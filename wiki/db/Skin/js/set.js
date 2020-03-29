// ----------------------------------------------------------------------------
// markItUp!
// ----------------------------------------------------------------------------
// Copyright (C) 2008 Jay Salvat
// http://markitup.jaysalvat.com/
// ----------------------------------------------------------------------------
myWikiSettings = {
    nameSpace:          "wiki", // Useful to prevent multi-instances CSS conflict
    // previewParserPath:  "~/sets/wiki/preview.php",
    onShiftEnter:       {keepDefault:false, replaceWith:'\n\n'},
    markupSet:  [
        {name:'Heading 1', key:'1', openWith:'=', closeWith:'=\n', placeHolder:'Your title here...' },
        {name:'Heading 2', key:'2', openWith:'==', closeWith:'==\n', placeHolder:'Your title here...' },
        {name:'Heading 3', key:'3', openWith:'===', closeWith:'===\n', placeHolder:'Your title here...' },
        {name:'Heading 4', key:'4', openWith:'====', closeWith:'====\n', placeHolder:'Your title here...' },
        {name:'Heading 5', key:'5', openWith:'=====', closeWith:'=====\n', placeHolder:'Your title here...' },
          {separator:'---------------' },        
        {name:'Bold', key:'B', openWith:"'''", closeWith:"'''"}, 
        {name:'Bold Blue', key:'U', openWith:"'''b:", closeWith:"'''", placeHolder:'Blue Bold...'}, 
        {name:'Bold Red', key:'R', openWith:"'''r:", closeWith:"'''", placeHolder:'Red Bold...'}, 
        {name:'Bold Green', key:'G', openWith:"'''g:", closeWith:"'''", placeHolder:'Green Bold...'}, 
          {separator:'---------------' },
        {name:'Italic', key:'I', openWith:"''", closeWith:"''"}, 
        {name:'Bulleted list', openWith:'(!(*|!|*)!)'}, 
        {name:'Indent', openWith:'(!(:|!|:)!)'}, 
          {separator:'---------------' },
        {name:'Picture', key:'P', replaceWith:'[[Image:[![Image Name:!:]!]|[![Align]!]]]'}, 
        // {name:'Link', key:'L', openWith:'[[![Link]!] ', closeWith:']]', placeHolder:'Your text to link here...' },
        {name:'Link', key:'L', openWith:'[[', closeWith:']]', placeHolder:'Your Internal link here...' },
        {name:'Url', openWith:'[[![Url:!:http://]!] ', closeWith:']', placeHolder:'Your extarnal link here...' },
          {separator:'---------------' },
        {name:'Before TOC', openWith:'__BEGINBEFORETOC__\n', closeWith:'\n__ENDBEFORETOC__\n', placeHolder:'Your text before TOC here...\n' },
        {name:'No TOC', openWith:'__NOTOC__\n', closeWith:'\n' },
        
        // {name:'Stroke through', key:'S', openWith:'<s>', closeWith:'</s>'}, 
        // {separator:'---------------' },
        // {name:'Quotes', openWith:'(!(> |!|>)!)'},
        // {name:'Code', openWith:'(!(<source lang="[![Language:!:php]!]">|!|<pre>)!)', closeWith:'(!(</source>|!|</pre>)!)'}, 
        // {separator:'---------------' },
        // {name:'Preview', call:'preview', className:'preview'}
    ]
}
