using MassTransit;
using Microsoft.EntityFrameworkCore;
using PaymentService.Data;
using PaymentService.Handlers;
using PaymentService.Services;
using Serilog;
using Shared.Domain.Events;
using System.Reflection;
using FluentValidation;
using FluentValidation.AspNetCore;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Diagnostics.HealthChecks;

var builder = WebApplication.CreateBuilder(args);

// Configure Serilog (simplified for demo)
Log.Logger = new LoggerConfiguration()
    .MinimumLevel.Information()
    .WriteTo.Console()
    .CreateLogger();

builder.Host.UseSerilog();

// Add services to the container
builder.Services.AddControllers();
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen(c =>
{
    c.SwaggerDoc("v1", new Microsoft.OpenApi.Models.OpenApiInfo
    {
        Title = "Payment Service API",
        Version = "v1",
        Description = "API for managing payments, accounts, and transactions",
        Contact = new Microsoft.OpenApi.Models.OpenApiContact
        {
            Name = "CI/CD Azure Team",
            Email = "team@cicdazure.com"
        }
    });
    
    // Include XML comments
    var xmlFile = $"{Assembly.GetExecutingAssembly().GetName().Name}.xml";
    var xmlPath = Path.Combine(AppContext.BaseDirectory, xmlFile);
    if (File.Exists(xmlPath))
    {
        c.IncludeXmlComments(xmlPath);
    }
});

// Database (commented out for demo - no database required)
// builder.Services.AddDbContext<PaymentDbContext>(options =>
//     options.UseNpgsql(builder.Configuration.GetConnectionString("DefaultConnection")));

// MediatR (commented out for demo)
// builder.Services.AddMediatR(cfg => {
//     cfg.RegisterServicesFromAssembly(Assembly.GetExecutingAssembly());
//     cfg.RegisterServicesFromAssembly(typeof(Shared.Domain.Commands.BaseCommand).Assembly);
// });

// FluentValidation (commented out for demo)
// builder.Services.AddFluentValidationAutoValidation();
// builder.Services.AddValidatorsFromAssembly(Assembly.GetExecutingAssembly());

// MassTransit with RabbitMQ (commented out for demo)
// builder.Services.AddMassTransit(x =>
// {
//     x.AddConsumers(Assembly.GetExecutingAssembly());
//     
//     x.UsingRabbitMq((context, cfg) =>
//     {
//         cfg.Host(builder.Configuration.GetConnectionString("RabbitMQ"));
//         
//         // Configure endpoints
//         cfg.ConfigureEndpoints(context);
//         
//         // Configure message retry
//         cfg.UseMessageRetry(r => r.Interval(3, TimeSpan.FromSeconds(5)));
//     });
// });

// Application Services (commented out for demo - using DemoController instead)
// builder.Services.AddScoped<IPaymentService, PaymentService.Services.PaymentService>();
// builder.Services.AddScoped<ITransactionService, TransactionService>();
// builder.Services.AddScoped<IAccountService, AccountService>();

// Health Checks
builder.Services.AddHealthChecks();

var app = builder.Build();

// Configure the HTTP request pipeline
// Always enable Swagger for demo
app.UseSwagger();
app.UseSwaggerUI(c =>
{
    c.SwaggerEndpoint("/swagger/v1/swagger.json", "Payment Service API v1");
    c.RoutePrefix = "swagger";
    c.DocumentTitle = "Payment Service API Documentation";
});

// app.UseHttpsRedirection(); // Commented out for demo - using HTTP only
app.UseAuthorization();
app.MapControllers();
app.MapHealthChecks("/health");

// Ensure database is created (commented out for demo)
// using (var scope = app.Services.CreateScope())
// {
//     var context = scope.ServiceProvider.GetRequiredService<PaymentDbContext>();
//     await context.Database.EnsureCreatedAsync();
// }

try
{
    Log.Information("Starting PaymentService");
    await app.RunAsync();
}
catch (Exception ex)
{
    Log.Fatal(ex, "PaymentService terminated unexpectedly");
}
finally
{
    Log.CloseAndFlush();
}
