const fs = require("fs");

task("doc", "Generates project documentation")
  .setAction(async (taskArgs, hre) => {
    await hre.run("docgen");
    sleep(1000);

    var showdown  = require('showdown');
    showdown.setFlavor('github');

    converter = new showdown.Converter({completeHTMLDocument: false, tables: true});
    text = fs.readFileSync("./docs/index.md", {encoding:'utf8', flag:'r'});
    html      = converter.makeHtml(text);

    prefix = `
    <html>
    <head>
      <link rel="stylesheet" type="text/css" href="https://cdnjs.cloudflare.com/ajax/libs/foundation/5.5.2/css/foundation.min.css">
    <link rel="stylesheet" type="text/css" href="https://maxcdn.bootstrapcdn.com/font-awesome/4.4.0/css/font-awesome.min.css">
    <style>
    html,
    body {
        width: 100%;
        height: 100%;
        margin: 0;
        padding: 0;
    }
    
    html {
        overflow-x: hidden;
    }
    
    @keyframes squeezeBody {
        from { width: 100%; }
        to { width: calc(100% - 300px); }
    }
    
    @-webkit-keyframes squeezeBody {
        from { width: 100%; }
        to { width: calc(100% - 300px); }
    }
    
    @keyframes stretchBody {
        from { width: calc(100% - 300px); }
        to { width: 100%; }
    }
    
    @-webkit-keyframes stretchBody {
        from { width: calc(100% - 300px); }
        to { width: 100%; }
    }
    
    h1, h2, h3, h4, h5, h6 {
        font-family: 'Old Standard TT', serif;
        font-weight: bold;
    }
    
    h3 {
        border-bottom: 1px solid #ddd;
    }
    
    .serif {
        font-family: 'Old Standard TT', serif;
    }
    
    .top-bar {
        height: 45px;
        min-height: 45px;
        position: absolute;
        top: 0;
        right: 0;
        left: 0;
    }
    
    .bars-lnk {
        color: #fff;
    }
    
    .bars-lnk i {
        display: inline-block;
        margin-left: 10px;
        margin-top: 7px;
    }
    
    .bars-lnk img {
        display: inline-block;
        margin-left: 10px;
        margin-top: -15px;
        margin-right: 15px;
        height: 35px;
    }
    
    .lateral-menu {
        background-color: #333;
        color: rgb(144, 144, 144);
        width: 300px;
        font-family: 'Open Sans', 'Myriad Pro', 'Lucida Grande', 'Lucida Sans Unicode', 'Lucida Sans', Geneva, Verdana, sans-serif;
    }
    
    .lateral-menu label {
        color: rgb(144, 144, 144);
    }
    
    .lateral-menu-content {
        padding-left: 10px;
        height: 100%;
        font-size: 12px;
        font-style: normal;
        font-variant: normal;
        font-weight: bold;
        line-height: 16px;
    }
    
    .lateral-menu-content .title{
        padding-top: 15px;
        font-size: 2em;
        height: 45px;
    }
    
    .lateral-menu-content-inner {
        overflow-y: auto;
        height: 100%;
        padding-top: 10px;
        padding-bottom: 50px;
        padding-right: 10px;
        font-size: 0.9em;
    }
    
    
    
    .container {
        display: flex;
        flex-direction: row;
        flex-wrap: nowrap;
        justify-content: center;
        align-items: stretch;
        width: 100%;
        height: 100%;
        padding-top: 65px;
    }
    
    .container>* {
        display: block;
        width: 50%;
        margin-left: 10px;
        margin-right: 10px;
        max-height: 100%;
    }
    
    .container textarea {
        resize: none;
        font-family: Consolas,"Liberation Mono",Courier,monospace;
        height: 97%;
        max-height: 97%;
        width: 45%;
    }
    
    #preview {
        height: 97%;
        max-height: 97%;
        border: 1px solid #eee;
        overflow-y: scroll;
        width: 55%;
        padding: 10px;
    }
    
    pre {
        white-space: pre-wrap;       /* css-3 */
        white-space: -moz-pre-wrap;  /* Mozilla, since 1999 */
        white-space: -pre-wrap;      /* Opera 4-6 */
        white-space: -o-pre-wrap;    /* Opera 7 */
        word-wrap: break-word;       /* Internet Explorer 5.5+ */
        background-color: #f8f8f8;
        border: 1px solid #dfdfdf;
        margin-top: 1.5em;
        margin-bottom: 1.5em;
        padding: 0.125rem 0.3125rem 0.0625rem;
    }
    
    pre code {
        background-color: transparent;
        border: 0;
        padding: 0;
    }
    
    
    .modal-wrapper {
        position: absolute;
        width: 100%;
        height: 100%;
        top: 0;
        left: 0;
        z-index: 999;
        background-color: rgba(51,51,51,0.5);
    }
    
    .modal-inner {
        margin-top: 200px;
        margin-left: auto;
        margin-right: auto;
        width: 600px;
        height: 225px;
        background-color: #fff;
        opacity: 1;
        z-index: 1000;
    }
    
    .modal-close-btn {
        float: right;
        display: inline-block;
        margin-right: 5px;
        color: #ff4336;
    }
    
    .modal-close-btn:hover {
        float: right;
        display: inline-block;
        margin-right: 5px;
        color: #8d0002;
    }
    
    .modal-topbar {
        clear: both;
        height: 25px;
    }
    
    .modal-inner .link-area {
        margin: 10px;
        height: 170px;
    
    }
    
    .modal-inner textarea {
        width: 100%;
        height: 100%;
        margin: 0;
        padding: 0;
    }
    
    .version {
        color: white;
        font-size: 0.8em !important;
    }
    body {
        padding-left: 20px;
        padding-right: 20px;
    }
    </style>
    </head>
    <body>
    `;

    fs.writeFileSync("./docs/index.html", prefix + html, function (err) {
        if (err) throw err;
    });

    console.log("✅ Generated docs.")
  });

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: "0.8.9",
};

function sleep(milliseconds) {
  const date = Date.now();
  let currentDate = null;
  do {
    currentDate = Date.now();
  } while (currentDate - date < milliseconds);
}