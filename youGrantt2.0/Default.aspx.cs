using System;
using System.Collections.Generic;
using System.Collections.Specialized;
using System.Linq;
using System.Web;
using System.Web.UI;
using System.Web.UI.WebControls;
using YouTrackSharp.Admin;
using YouTrackSharp.Infrastructure;
using YouTrackSharp.Issues;
using YouTrackSharp.Projects;
using YouTrackSharp.CmdLets;

namespace youGrantt2._0
{
    public partial class Default : System.Web.UI.Page
    {
        static Connection conn = null;
        static ProjectManagement proj_manage = null;
        public static IssueManagement issue_manage = null;

        public static IEnumerable<Project> projects = null;
        public static IEnumerable<Issue> issues = null;

        private static readonly DateTime date = DateTime.Today;
        private static readonly int year = date.Year, month = date.Month;

        public static bool issues_ready = false;

        protected void Page_Load(object sender, EventArgs e)
        {
            if (Request.QueryString["host"] != null)
            {
                if (conn == null)
                    conn = new Connection(Request.QueryString["host"]);
            }
            else {
                if (conn == null)
                    conn = new Connection("pc", 8081);
            }
            if (SocketHandler.active_project != null)
            {
                Response.Cookies["active_project_name"].Value = SocketHandler.active_project.Name;
                Response.Cookies["active_project_name"].Expires = DateTime.Now.AddDays(1d);
                Response.Cookies["active_project_short_name"].Value = SocketHandler.active_project.ShortName;
                Response.Cookies["active_project_short_name"].Expires = DateTime.Now.AddDays(1d);
                if (Response.Cookies["project_start_time"].Value == null)
                {
                    Response.Cookies["project_start_time"].Value = DateTime.Now.Day.ToString() + '-' + DateTime.Now.Month.ToString() + '-' + DateTime.Now.Year.ToString();
                    Response.Cookies["project_start_time"].Expires = DateTime.Now.AddDays(1d);
                }
                Response.Cookies["project_duration"].Value = "100";
                Response.Cookies["project_duration"].Expires = DateTime.Now.AddDays(1d);

                if (issue_manage == null && conn != null)
                {
                    issue_manage = new IssueManagement(conn);
                }

                if (issues == null)
                {
                    issues = Default.issue_manage.GetAllIssuesForProject(SocketHandler.active_project.ShortName);
                    issues_ready = true;
                }
            }
            if (Response.Cookies["user"].Value != null && Response.Cookies["password"] != null
                && Session["user"].ToString().Length == 0 && Session["password"].ToString().Length == 0)
            {
                try
                {
                    conn.Authenticate(Response.Cookies["user"].Value, Response.Cookies["password"].Value);
                    Session["user"] = Response.Cookies["user"].Value;
                    Session["password"] = Response.Cookies["password"].Value;
                    if (proj_manage == null)
                        proj_manage = new ProjectManagement(conn);
                    if (projects == null)
                        projects = proj_manage.GetProjects();
                    if (issue_manage == null)
                        issue_manage = new IssueManagement(conn);
                }
                catch (System.Security.Authentication.AuthenticationException aex) {
                    Response.Redirect("/");
                }
            }

            if (Request.QueryString["logout"] == "1")
            {
                Session.Clear();
                Response.Cookies.Clear();
                conn.Logout();
                Response.Redirect("/");
            }
        }

        public static DateTime UnixTimeStampToDateTime(double unixTimeStamp)
        {
            // Unix timestamp is seconds past epoch
            System.DateTime dtDateTime = new DateTime(1970, 1, 1, 0, 0, 0, 0, System.DateTimeKind.Utc);
            dtDateTime = dtDateTime.AddMilliseconds(unixTimeStamp).ToLocalTime();
            return dtDateTime;
        }


        public static bool IsAuth() {
            if (conn != null)
                return conn.IsAuthenticated;
            return false;
        }

        protected void SetCookieInside(string name, string value)
        {
            var cookie_user = new HttpCookie(name, value);
            cookie_user.Expires.AddDays(5);
            Response.SetCookie(cookie_user);
        }

        public void sign_in_btn_Click(object sender, EventArgs e)
        {

        }

        public static void GetProjects()
        {
            projects = proj_manage.GetProjects();
        }

        public static void GetIssues(string shortname) 
        {
            issues = issue_manage.GetAllIssuesForProject(shortname);
        }

        public static void SetCookie(string name, string value) 
        {
            
        }

        public static Project GetProjectNameById(string id)
        {
            foreach (Project p in projects)
            {
                if (p.ShortName == id)
                    return p;
            }
            return null;
        }

        protected void SignInButton_Click(object sender, EventArgs e)
        {
            NameValueCollection value_coll = Request.Form;
            try
            {
                conn.Authenticate(value_coll["login"], value_coll["password"]);
                Session["user"] = value_coll["login"];
                Session["password"] = value_coll["password"];

                proj_manage = new ProjectManagement(conn);
                Response.Cookies["user"].Value = Session["user"].ToString();
                Response.Cookies["user"].Expires = DateTime.Now.AddDays(1d);
                Response.Cookies["password"].Value = Session["password"].ToString();
                Response.Cookies["password"].Expires = DateTime.Now.AddDays(1d);

                projects = proj_manage.GetProjects();
            }
            catch
            {
                Response.Redirect("/");
            }
        }


    }
}