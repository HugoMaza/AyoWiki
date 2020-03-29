/* Any JavaScript here will be loaded for all users on every page load. */


/************************************************************
 * History.pm required javascript
 ************************************************************/
function setStyle(objId, style, value)
{
   document.getElementById(objId).style[style]= value;
}
function GetCbList(form)
{
  var i;
  var cblist = new String();
  var len = form.elements.length;
  cblist = "";
  for(i=0;i<len;i++) 
  {
    if(form.elements[i].type == 'checkbox')
    {
      if(form.elements[i].checked) 
      {
        cblist += String(i) + ":";
      }
    }
  }
  return cblist.substr(0,cblist.length-1); // Chop off final colon;
}
function SetCbList(list,form)
{
  var i;
  var cblist = new String(list);
  var a = new Array();
  if(cblist=="") {return;} 
  a = cblist.split(":"); // split the string into an array at every comma.
  for(i=0; i<a.length; i++)
  {
    if(form.elements[a[i]].type == 'checkbox') // make sure its a checkbox to avoid error.
    {
      form.elements[a[i]].checked=true; // set the check mark.
    }
  }
}
function SetCbColor(form)
{
  var i;
  var len = form.elements.length;
  var color = new Array("#ffffcc","#ccffcc","#ffcccc");
  var ci=-1;
  for(i=0;i<len;i++)
  {
    if(form.elements[i].type == 'checkbox')
    {
      if(form.elements[i].checked) 
      {
        ci++; if(ci>2)ci=2;
        setStyle(form.elements[i].name,"background",color[ci]);
      }
      else setStyle(form.elements[i].name,"background","#ffffff");
    }
  }
  if(ci==2)
  {
    for(i=0;i<len;i++)
    {
      if(form.elements[i].type == 'checkbox')
      {
        if(form.elements[i].checked) 
        {
          setStyle(form.elements[i].name,"background",color[2]);
        }
        else setStyle(form.elements[i].name,"background","#ffffff");
      }
    }
  }
}
function ChkCbList(form)
{
  var i;
  var cnt=0;
  var len = form.elements.length;
  for(i=0; i<len; i++)
  {
    if(form.elements[i].type == 'checkbox')
    {
      if(form.elements[i].checked) 
      {
        cnt++;
      }
    }
  }
  if(cnt>2) { alert("Select only 2"); return false; }
  else return true;
}

/************************************************************
 * Collapsible div sections required javascript
 ************************************************************/
var collapsiblecount = 0;
function Begin_Collapsible_Section()
{
   document.writeln('<!--------------Begin Collapsible Section------------>');
   document.writeln('<div class="collapsibleheader" onclick="DoCollapse(ccc'+collapsiblecount+');">[show/hide]</div>');
   document.writeln('<div class="collapsiblebody" style="display: none;" id="ccc'+collapsiblecount+'">');
   collapsiblecount++;
}
function End_Collapsible_Section()
{
   document.writeln('</div>');
   document.writeln('<!--------------End Collapsible Section------------>');
}
function DoCollapse(obj){
 if("none" == obj.style.display){
  obj.style.display = "block";
 } else {
  obj.style.display = "none";
 }
}
/************************************************************
 * Session.pm required javascript
 ************************************************************/
function CheckForm(form)  /* account form */
{
  //var emailre=/^[\w][\w\.-]*[\w]@[\w][\w\.-]*[\w]\.[a-zA-Z][a-zA-Z\.]*[a-zA-Z]$/;
  var emailre=/^[\w][\w\.-]*[\w]@[\w][\w\.-]*[\w]$/;  //easier - no .com check
  var wordre=/^\S+$/;
  var unok = wordre.test(form.username.value);
  var pwok = wordre.test(form.password.value);
  var emailok = emailre.test(form.email.value);
  if(!unok) { alert("invalid username - a-z A-Z 0-9 _ no spaces"); return 0; }
  if(!pwok) { alert("invalid password - a-z A-Z 0-9 _ no spaces "); return 0; }
  if(!emailok) { alert("invalid email (user@domain.com)"); return 0; }
  return 1;
}
/************************************************************
 * Sidebar Content Changer required javascript
 ************************************************************/
function Change_Sidebar_Content(html)
{
   document.getElementById('sidebar').innerHTML="<div class='sidebar'>"+html+"</div>";
}
/*-----------------------------------------------------------------------
* Added Change_Sidebar_Content.
*
*-----------------------------------------------------------------------*/

