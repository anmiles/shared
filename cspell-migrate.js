const fs = require('fs');
const path = require('path');

const settingsDir = '.vscode';
const settingsFile = path.join(settingsDir, 'settings.json');
const cspellConfigFile = 'cspell.json';
const packageJSONFile = 'package.json';

const settingsFileWordsKey = 'cSpell.words';
const settingsFileIgnorePathsKey = 'cSpell.ignorePaths';

const cspellConfig = {
	"version": "0.2",
	"enabled": true,
	"language": "en",
	"minWordLength": 4,
	"enableGlobDot": true,
	"useGitignore": true,
	"ignorePaths": [
		".git",
		"package-lock.json"
	],
	"dictionaries": [],
	"words": [],
	"flagWords": []
};

const savedCspellConfig = fs.existsSync(cspellConfigFile)
	? JSON.parse(fs.readFileSync(cspellConfigFile).toString())
	: undefined;

if (savedCspellConfig) {
	cspellConfig.language = savedCspellConfig.language;
	cspellConfig.dictionaries = savedCspellConfig.dictionaries;
	cspellConfig.words.push(...savedCspellConfig.words);
	cspellConfig.ignorePaths.push(...savedCspellConfig.ignorePaths);
}

if (fs.existsSync(settingsFile)) {
	const settings = JSON.parse(fs.readFileSync(settingsFile).toString());

	if (settings[settingsFileWordsKey]) {
		cspellConfig.words.push(...settings[settingsFileWordsKey]);
		delete settings[settingsFileWordsKey];
	}

	if (settings[settingsFileIgnorePathsKey]) {
		cspellConfig.ignorePaths.push(...settings[settingsFileIgnorePathsKey]);
		delete settings[settingsFileIgnorePathsKey];
	}

	if (Object.keys(settings).length === 0){
		fs.rmSync(settingsFile);
		if (fs.readdirSync(settingsDir).length === 0) {
			fs.rmSync(settingsDir, { recursive: true });
		}
	} else {
		console.log(settings);
		fs.writeFileSync(settingsFile, JSON.stringify(settings, null, '\t'));
	}
}

cspellConfig.words = [...new Set(cspellConfig.words.map(str => str.toLowerCase()).sort())];
cspellConfig.ignorePaths = [...new Set(cspellConfig.ignorePaths.map(str => str.toLowerCase()).sort())];

console.log({
	words: cspellConfig.words,
	ignorePaths: cspellConfig.ignorePaths,
});

fs.writeFileSync(cspellConfigFile, JSON.stringify(cspellConfig, null, '\t'));

const packageJSON = JSON.parse(fs.readFileSync(packageJSONFile).toString());
if (!packageJSON.scripts.spellcheck) {
	packageJSON.scripts = Object.fromEntries([
		['spellcheck', 'cspell .'],
		...Object.entries(packageJSON.scripts),
	]);
	fs.writeFileSync(packageJSONFile, JSON.stringify(packageJSON, null, '\t'));
}
