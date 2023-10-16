// 创建构造器，添加配置项、各种依赖注入等
var builder = WebApplication.CreateBuilder(args);
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();


// 创建WebApplication
var app = builder.Build();

// 添加中间件(请求管道)
if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

// 配置路由
app.MapGet("/hello", () => { return "Hello World"; });
app.MapGet("/time", () => { return DateTime.Now.ToString("yyyy-MM-dd HH:mm:ss"); });


// 启动服务
app.Run();