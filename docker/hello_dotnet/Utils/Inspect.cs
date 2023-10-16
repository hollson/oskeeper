namespace Utils
{
    /// <summary>
    /// 系统信息
    /// </summary>
    public class Inspect
    {
        /// <summary>
        /// 程序运行时相关的环境变量
        /// </summary>
        /// <returns></returns>
        public static object Info()
        {
            return new
            {
                // 操作系统
                OS = Environment.OSVersion.VersionString,
                // 当前用户
                UserName = Environment.UserName,
                // Dotnet版本
                DotnetVersion = Environment.Version.ToString(),
                // 主机时区
                TimeZone = Environment.GetEnvironmentVariable("TZ"),
                // 主机时间
                HostTime = DateTime.Now.ToString("yyyy-MM-dd HH:mm:ss")
            };
        }
    }
}