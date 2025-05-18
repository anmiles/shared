const fs = require('fs');

const cspellConfigFile = 'cspell.json';
const cspellConfig = JSON.parse(fs.readFileSync(cspellConfigFile).toString());

cspellConfig.language += ',ru';
cspellConfig.dictionaries.push('ru_ru');

console.log({
	words: cspellConfig.words,
	ignorePaths: cspellConfig.ignorePaths,
});

fs.writeFileSync(cspellConfigFile, JSON.stringify(cspellConfig, null, '\t'));
