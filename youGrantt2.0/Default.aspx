<%@ Page Language="C#" AutoEventWireup="true" CodeBehind="Default.aspx.cs" Inherits="youGrantt2._0.Default" %>

<%@ Register Assembly="System.Web.DataVisualization, Version=4.0.0.0, Culture=neutral, PublicKeyToken=31bf3856ad364e35" Namespace="System.Web.UI.DataVisualization.Charting" TagPrefix="asp" %>

<!DOCTYPE html>
<% 
%>
<html xmlns="http://www.w3.org/1999/xhtml">
<head runat="server">
    <meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
    <title>youGantt</title>
    <link rel="stylesheet" href="semantic/dist/semantic.min.css" />
    <link rel="stylesheet" href="Content/codebase/dhtmlxgantt.css" />
    <script type="text/javascript" src="Scripts/jquery-3.0.0.min.js"></script>
    <script type="text/javascript" src="semantic/dist/semantic.min.js"></script>
    <script type="text/javascript" src="Content/codebase/dhtmlxgantt.js"></script>
    <script type="text/javascript">
        var add_task = function (n, s, t, d, p) {
            var taskId;
            if (p === undefined) {
                taskId = gantt.addTask({
                    id: s,
                    text: n,
                    start_date: t,
                    duration: d
                });
            } else {
                taskId = gantt.addTask({
                    id: s,
                    text: n,
                    start_date: t,
                    duration: d
                }, p);
            }
            return taskId;
        }
        function setCookie(c_name,value,exdays) {
            var exdate=new Date();
            exdate.setDate(exdate.getDate() + exdays);
            var c_value=escape(value) + ((exdays==null) ? "" : ";expires="+exdate.toUTCString());
            document.cookie=c_name + "=" + c_value;
        }
        $(document).ready(function () {
            $('.ui.dropdown').dropdown();
            $('.sign_in_btn').click(function () {
                $('.sign_in_frm').show(100);
            });
            $('.ui.form').form({
                fields: {
                    login: 'empty',
                    password: 'empty'
                }
            });
            $('.close').click(function () {
                $('.sign_in_frm').hide();
            });
            /*$('.auth').click(function () {
                $.post('/login', {
                    login: $("input[name='login']").val(),
                    password: $("input[name='password']").val()
                }).done(function (data) {

                });
            });*/
            var socket;
            if (typeof (WebSocket) !== 'undefined') {
                socket = new WebSocket("<%=("ws://" +  Request.Url.Host + ":" + Request.Url.Port + "/SocketHandler.ashx") %>");
            } else {
                socket = new MozWebSocket("<%=("ws://" +  Request.Url.Host + ":" + Request.Url.Port + "/SocketHandler.ashx") %>");
            }

            socket.onmessage = function (msg) {
                var curr_date = new Date();
                var date_str = curr_date.getDay() + '-' + curr_date.getMonth() + '-' + curr_date.getFullYear();

                setCookie("active_project_name", msg.data.toString().substring(2, msg.data.toString().length), 5);
                setCookie("active_project_short_name", $('.projects :selected').text(), 5);
                setCookie("project_start_time", date_str, 5);
                setCookie("project_duration", 2000);

                if (msg.data[0] == '%' && msg.data[1] == '%') {
                    add_task(msg.data.toString().substring(2, msg.data.toString().length),
                        $('.projects :selected').text(),
                        date_str,
                        2000);
                }

                window.location.href = "/";
            }

            socket.onclose = function (event) {
                console.log('Sock lost...');
            };

            $('.sign_out_btn').click(function () {
                window.location.href = "?logout=1";
            });

            $('.projects').change(function () {
                socket.send("%%" + $('.projects :selected').text());
            });
        });
    </script>
    <style type="text/css">
    </style>
</head>
<body>
    <div class="ui huge menu">
        <div class="item">
            <a class="ui green label large">
                <% if (Session["user"] != null)
                   {
                %>
                <%= Session["user"]%>
                <%}
                   else
                   {%>
                <%="Not Logged"%>
                <%}%>
            </a>
        </div>
        <div class="right menu">
            <div class="item">
                <select name="projects" class="ui fluid search dropdown projects">
                    <option value="">Select active  project</option>
                    <%  if (Session["user"] != null)
                        {
                            default_aspx.GetProjects();
                            foreach (YouTrackSharp.Projects.Project p in projects)
                            { %>
                            <%= "<option value=" + p.ShortName + ">" + p.ShortName + "</option>" %>
                    <%      }
                        } %>
                </select>
            </div>
            <div class="item">
                <% if (Session["user"] == null)
                   {%>
                <%= "<div class='ui primary button sign_in_btn'>Sign In</div>"%>
                <% }
                   else
                   { %>
                <%= "<button class='ui primary button sign_out_btn'>Sign Out</button>"%>
                <%} %>
            </div>
        </div>
    </div>
    <form class="ui form stacked compact segment sign_in_frm" style="display: none; z-index: 3; left: 10%; position: fixed;" runat="server" method="post" action="/">
        <i class="close link icon" style="margin-right: 0;"></i>
        <h4 style="top: 0;">Youtrack Authorize</h4>
        <div class="two fields">
            <div class="field">
                <label>Login</label>
                <input type="text" name="login" />
            </div>
            <div class="field">
                <label>Password</label>
                <input type="password" name="password" />
            </div>
        </div>
        <div class="ui divider"></div>
        <asp:Button ID="SignInButton" class="ui blue button auth" Text="Submit" runat="server" OnClick="SignInButton_Click" />
        <div class="ui error message"></div>
    </form>
    <div id="gantt_here" style='width: 100%; height: 70%; margin: 0 auto;'></div>
    <script type="text/javascript">
        gantt.config.subscales = [
           { unit: "week", step: 2, date: "Week #%W" }
        ];
        gantt.config.scale_height = 60;
        gantt.config.scale_unit = "day";
        gantt.config.step = 1;
        gantt.config.duration_unit = "day";
        gantt.config.duration_step = 5;
        gantt.init("gantt_here");
        <%
        if (Response.Cookies["active_project_name"].Value != null) { 
        %>
        <%= "var proj = add_task(" + '"' + Response.Cookies["active_project_name"].Value + '"' +"," 
                        + '"' + Response.Cookies["active_project_short_name"].Value + '"' + "," 
                        + '"' + Response.Cookies["project_start_time"].Value + '"' + "," 
                        + '"' + Response.Cookies["project_duration"].Value + '"' + ");" %>
        <%= "$('.projects :contains(" + Response.Cookies["active_project_short_name"].Value + ")').attr('selected', 'selected');" %>
        <% } %>
        <% 
            if (default_aspx.issues_ready && default_aspx.IsAuth()) { 
                var links = new List<object>();
                foreach(var issue in default_aspx.issues){
                    dynamic dynamicIssue = issue.ToExpandoObject();
                    
                    var summary = dynamicIssue.summary;
                    var id = dynamicIssue.id;
                    var affected_version = dynamicIssue.affectsversion;
                    var estimation = dynamicIssue.estimation[0];
                    var link = dynamicIssue.links;
                    DateTime tm = default_aspx.UnixTimeStampToDateTime(dynamicIssue.created);
                    
        %>
        <%= "add_task(" + 
                    '"' + summary + '"' + ',' + 
                    '"' + id + '"' + ',' +
                    '"' + tm.Day + "-" + tm.Month + "-" + tm.Year + '"' + ',' +
                    '"' + estimation + '"' + ','
                    + " proj);" %>
        <%      
                }
            }
        %>
    </script>
</body>
</html>
