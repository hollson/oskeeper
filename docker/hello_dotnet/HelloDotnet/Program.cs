// ����������������������������ע���
var builder = WebApplication.CreateBuilder(args);
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();

// ����WebApplication
var app = builder.Build();

// ����м��(����ܵ�)
app.UseSwagger();
app.UseSwaggerUI();

// ����·��
app.MapGet("/hello", () => { return "Hello World"; });
app.MapGet("/inspect", () => { return Utils.Inspect.Info(); });

// ��������
app.Run();