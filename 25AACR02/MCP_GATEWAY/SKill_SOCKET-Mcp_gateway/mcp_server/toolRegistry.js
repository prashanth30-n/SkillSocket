const { webSearch } = require('../tools/websearch');
class ToolRegistry{
    constructor(){
        this.tools={};
        this.registerDefaultTools();
    }
    registerDefaultTools(){
         this.register('web_search', webSearch);
    }
    register(name,func){
        this.tools[name]=func;
    }
    get(name){
         if (!this.tools[name]) throw new Error(`Tool "${name}" not found.`);
        return this.tools[name];
    }
}
module.exports=ToolRegistry