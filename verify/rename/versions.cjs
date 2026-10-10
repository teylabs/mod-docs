const {createRequire}=require('node:module');
const path=require('node:path');
const app=process.argv[2];const req=createRequire(path.resolve(app,'package.json'));
const versions={node:process.version};
for(const name of ['@babel/parser','@vue/compiler-sfc','typescript','vite','vue','react']){try{versions[name]=req(name+'/package.json').version}catch{}}
console.log(JSON.stringify(versions,null,2));
