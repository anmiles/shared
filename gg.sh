#!/bin/bash

# SYNOPSIS
#	 Grep files and their contents
# DESCRIPTION
#	 Grep specified text in specified files existing in current git repository in the current directory or its subdirectories
# PARAMETER file_pattern
#	 Pattern to regex search the file
# PARAMETER text_pattern
#	 Pattern to regex search the text in the file
# PARAMETER format
#	 Output format:
#			 text (default) - colored human-friendly output
#			 files - plain list of files
#			 lines - plain list of lines (or files if text_pattern missing)
#			 json - machine-readable JSON
# PARAMETER mockFile
#	 JSON file with mock file system (for test purposes)
# PARAMETER value
#	 Return value of the first matched group. Not applicable if format == 'files' or text_pattern missing
# EXAMPLES:
#	 gg '\.ts$'
#	 # search all *.ts files
#	 gg '\.ts$' -format json
#	 # get all *.ts files in JSON format
#	 gg '\.ts$' 'import \{(.+)\}'
#	 # get all *.ts files and their named imports
#	 gg '\.ts$' 'import \{(.+)\}' -value
#	 # get all *.ts files and their named imports (names only)
#	 gg '\.ts$' 'import \{(.+)\}' -format files
#	 # get all *.ts files that contains named imports
#	 gg '\.ts$' 'import \{(.+)\}' -format lines
#	 # get all named imports inside *.ts files
#	 gg '\.ts$' 'import \{(.+)\}' -format lines -value
#	 # get all named imports (names only) inside *.ts files
#	 gg '\.ts$' 'import \{(.+)\}' -format json
#	 # get all *.ts files and their named imports in JSON format
#	 gg '\.ts$' 'import \{(.+)\}' -format json -value
#	 # get all *.ts files and their named imports (names only) in JSON format

value=false

while [[ $# -gt 0 ]]; do
	key="$1"
	case $key in
		-file_pattern)
			file_pattern="$2"
			shift
			shift
			;;
		-text_pattern)
			text_pattern="$2"
			shift
			shift
			;;
		-format)
			format="$2"
			shift
			shift
			;;
		-mockFile)
			mockFile="$2"
			shift
			shift
			;;
		-value)
			value=true
			shift
			;;
		*)
			shift
			;;
	esac
done

# echo "file_pattern=$file_pattern"
# echo "text_pattern=$text_pattern"
# echo "format=$format"
# echo "mockFile=$mockFile"
# echo "value=$value"
# exit

if [[ -n "$mockFile" ]]; then
	mock=$(cat "$mockFile")
else
	mock=
fi

if [[ -n "$mock" ]]; then
	files=$(echo "$mock" | jq -r 'keys | .[]')
else
	files=$(git ls-files && git ls-files --exclude-standard --others | xargs -I {} test -f {})
fi

if [[ -n "$file_pattern" ]]; then
	files=$(echo "$files" | grep -iP "$file_pattern")
fi

fmt() {
	local text="$1"
	local ForegroundColor="$2"
	local BackgroundColor="$3"
	local parse="$4"

	declare -A ForegroundColors=(
		["Black"]=30
		["DarkBlue"]=34
		["DarkGreen"]=32
		["DarkCyan"]=36
		["DarkRed"]=31
		["DarkMagenta"]=35
		["DarkYellow"]=33
		["Gray"]=37
		["DarkGray"]=90
		["Blue"]=94
		["Green"]=92
		["Cyan"]=96
		["Red"]=91
		["Magenta"]=95
		["Yellow"]=93
		["White"]=97
	)

	declare -A BackgroundColors=(
		["Black"]=40
		["DarkBlue"]=44
		["DarkGreen"]=42
		["DarkCyan"]=46
		["DarkRed"]=41
		["DarkMagenta"]=45
		["DarkYellow"]=43
		["Gray"]=47
		["DarkGray"]=100
		["Blue"]=104
		["Green"]=102
		["Cyan"]=106
		["Red"]=101
		["Magenta"]=105
		["Yellow"]=103
		["White"]=107
	)

	result_length=0

	Colorize() {
		local str="$1"
		local ForegroundColor="$2"
		local BackgroundColor="$3"
		local f1="" b1="" c0=""

		if [ -z "$str" ]; then
			echo ""
			return
		fi

		((result_length += ${#str}))

		eseq="\033"

		if [ -n "$ForegroundColor" ]; then
			code="${ForegroundColors[$ForegroundColor]}"
			f1="$eseq[${code}m"
			c0="$eseq[m"
		fi

		if [ -n "$BackgroundColor" ]; then
			code="${BackgroundColors[$BackgroundColor]}"
			b1="$eseq[${code}m"
			c0="$eseq[m"
		fi

		echo " B1: ${b1} F1: ${f1} STR: ${str} C0: ${c0}" >> "/mnt/d/color.txt"
		echo -e "${b1}${f1}${str}${c0}"
	}

	output=()

	if [ -n "$text" ]; then
		if [ "$parse" == true ]; then
			IFS='{}' read -r -a parts <<< "$text"

			for ((i = 0; i < ${#parts[@]} - 1; i += 3)); do
				output+=("$(Colorize "${parts[i]}" "$ForegroundColor" "$BackgroundColor")")
				output+=("$(Colorize "${parts[i+2]}" "${parts[i+1]}" "$BackgroundColor")")
			done

			output+=("$(Colorize "${parts[-1]}" "$ForegroundColor" "$BackgroundColor")")
		else
			output+=("$(Colorize "$text" "$ForegroundColor" "$BackgroundColor")")
		fi
	fi

	printf "%s" "${output[@]}"
}

if [[ -n "$text_pattern" ]]; then
	json="["
	file_index=0

	if [[ ${#files} -gt 0 ]]; then
		while IFS= read -r file; do
			if [[ -n "$mock" ]]; then
				splitted=$(echo "$mock" | jq -r --arg file "$file" '.[$file]' | grep -iP -n "$text_pattern")
				readarray -t entries <<< "$splitted"
			else
				matches=$(grep -iP -n "$text_pattern" "$file")
				readarray -t entries <<< "$matches"
			fi

			case "$format" in
				"json")
					if [[ "$file_index" -gt "0" ]]; then json+=","; fi
					json_lines=()
					if [[ -n "$entries" ]]; then
						line_index=0
						for element in "${entries[@]}"; do
							line=$(echo "$element" | cut -d: -f1)
							value_str=$(echo "$element" | cut -d: -f2)
							if [[ "$line_index" -gt "0" ]]; then json_lines+=","; fi
							if $value; then value_str=$(echo "$element" | sed -r "s/^.*:$text_pattern.*$/\1/i"); fi
							json_lines+=$(jq -n --indent 0 --arg line $line --arg value "$value_str" '{line: $line|fromjson, value: $value}' )
							line_index=$(($line_index+1))
						done
					fi
					json+="{\"lines\":[$json_lines],\"file\":\"$file\"}"
					;;
				"files")
					if [[ -n "$entries" ]]; then
						echo "$file"
					fi
					;;
				*)
					token=$(uuidgen)
					if [[ "$file_index" -gt "0" && -n "$entries" && "$format" == "text" ]]; then
						echo ""
					fi

					for element in "${entries[@]}"; do
						if [[ -z $element ]]; then break; fi
						match=$(echo "$element" | grep -oP '^\d+:.+')
						line=$(echo "$match" | cut -d: -f1)
						entry=$(echo "$match" | cut -d: -f2-)
						value_str=$(echo "$entry" | perl -ne 'print "$1\n" if /'"$text_pattern"'/i')
						# echo "element = $element"
						# echo "match = $match"
						# echo "line = $line"
						# echo "entry = $entry"
						# echo "value_str = $value_str"
						if [[ "$format" == "lines" ]]; then
							if [[ "$value" == true ]]; then
								echo "$value_str"
							else
								echo "$entry"
							fi
						else
							output=$(fmt "$file" "DarkMagenta")":"$(fmt "$line" "DarkCyan")":"
							if [[ "$value" == true ]]; then
								output+=$(fmt "$value_str" "DarkYellow")
							else
								tokenized=$(echo "$entry" | perl -pe 's/'"$text_pattern"'/'"$token"'$&'"$token"'/gi')
								splitted=$(sed "s/$token/\n/g" <<< "$tokenized")
								readarray -t entry_split <<< "$splitted"

								i=0
								for entry_item in "${entry_split[@]}"; do
									i=$(($i+1))
									if [ $(($i % 2)) -eq 0 ]; then
										if [[ -n "$value_str" ]]; then
											escaped_delimiter=$(echo "$value_str" | sed 's/[]\/$*.^|[]/\\&/g')
											splitted=$(sed "s/$escaped_delimiter/\n/g" <<< "$entry_item")
											readarray -t parts <<< "$splitted"
											output+=$(fmt "${parts[0]}" "Red")
											output+=$(fmt "$value_str" "DarkYellow")
											output+=$(fmt "${parts[1]}" "Red")
										else
											output+=$(fmt "$entry_item" "Red")
										fi
									else
										output+=$(fmt "$entry_item")
									fi
								done
							fi
							echo "$output"
						fi
					done
					;;
			esac
			file_index=$(($file_index+1))
		done <<< "$files"
	fi

	json+="]"

	if [[ "$format" == "json" ]]; then
		echo $json
	fi
else
	case "$format" in
		"json")
			echo "$files" | jq -R -s -c 'split("\n") | map(select(length > 0))'
			;;
		*)
			echo "$files"
			;;
	esac
fi
