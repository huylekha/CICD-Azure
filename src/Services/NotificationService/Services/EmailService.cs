using SendGrid;
using SendGrid.Helpers.Mail;
using Serilog;
using Microsoft.Extensions.Configuration;

namespace NotificationService.Services;

public class EmailService : IEmailService
{
    private readonly ISendGridClient _sendGridClient;
    private readonly Microsoft.Extensions.Logging.ILogger _logger;
    private readonly string _fromEmail;

    public EmailService(ISendGridClient sendGridClient, Microsoft.Extensions.Logging.ILogger logger, IConfiguration configuration)
    {
        _sendGridClient = sendGridClient;
        _logger = logger;
        _fromEmail = configuration["SendGrid:FromEmail"] ?? "noreply@example.com";
    }

    public async Task<bool> SendEmailAsync(string to, string subject, string body)
    {
        try
        {
            var msg = new SendGridMessage()
            {
                From = new EmailAddress(_fromEmail, "Payment Service"),
                Subject = subject,
                PlainTextContent = body,
                HtmlContent = $"<p>{body}</p>"
            };

            msg.AddTo(new EmailAddress(to));

            var response = await _sendGridClient.SendEmailAsync(msg);

            if (response.IsSuccessStatusCode)
            {
                _logger.Information("Email sent successfully to {To}", to);
                return true;
            }
            else
            {
                _logger.Warning("Failed to send email to {To}. Status: {StatusCode}", to, response.StatusCode);
                return false;
            }
        }
        catch (Exception ex)
        {
            _logger.Error(ex, "Error sending email to {To}", to);
            return false;
        }
    }
}
