using System;
using System.Collections.Generic;
using System.Linq;
using System.Net.WebSockets;
using System.Text;
using System.Threading;
using System.Web;
using YouTrackSharp.Infrastructure;
using YouTrackSharp.Issues;
using YouTrackSharp.Projects;

namespace youGrantt2._0
{
    /// <summary>
    /// Сводное описание для SocketHandler
    /// </summary>
    public class SocketHandler : IHttpHandler
    {
        private static readonly List<WebSocket> clients = new List<WebSocket>();
        private static readonly ReaderWriterLockSlim __lock = new ReaderWriterLockSlim();
        private static bool wait_data = false;
        public static Project active_project = null;
        public static IEnumerable<Issue> issues = null;

        public void ProcessRequest(HttpContext context)
        {
            if (context.IsWebSocketRequest)
                context.AcceptWebSocketRequest(WebSocketRequest);
        }

        private async System.Threading.Tasks.Task WebSocketRequest(System.Web.WebSockets.AspNetWebSocketContext arg)
        {
            var socket = arg.WebSocket;

            while (true)
            {
                var buffer = new ArraySegment<byte>(new byte[80]);
                var result = await socket.ReceiveAsync(buffer, CancellationToken.None);
                string data = "";
                if (!wait_data)
                {
                    foreach (byte c in buffer)
                        if(c != 0)
                            data += (char)c;
                    if (data[0] == '%' && data[1] == '%') {
                        active_project = Default.GetProjectNameById(data.Substring(2));
                        await socket.SendAsync(new ArraySegment<byte>(Encoding.ASCII.GetBytes("%%" + active_project.Name)),
                                WebSocketMessageType.Text, true, CancellationToken.None);
                        
                        /*
                        foreach (Issue issue_tmp in issues) {
                            dynamic dyn_issue = issue_tmp.ToExpandoObject();
                        }*/
                        /*foreach (Issue iss in Default.issues) {
                            string tmp = iss.Id;
                            await socket.SendAsync(new ArraySegment<byte>(Encoding.ASCII.GetBytes(tmp)), 
                                WebSocketMessageType.Text, true, CancellationToken.None);
                        }*/
                    }
                }
                else
                {
            
                }
            }
        }

        public bool IsReusable
        {
            get { return true; }
        }
    }
}