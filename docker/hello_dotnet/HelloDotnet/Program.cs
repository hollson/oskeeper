// ����������������������������ע���
var builder = WebApplication.CreateBuilder(args);
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();


// ����WebApplication
var app = builder.Build();

// ����м��(����ܵ�)
if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

// ����·��
app.MapGet("/hello", () => { return "Hello World"; });
app.MapGet("/time", () => { return DateTime.Now.ToString("yyyy-MM-dd HH:mm:ss"); });


// ��������
app.Run();