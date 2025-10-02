using Serilog;

namespace NotificationService.Services;

public class SmsService : ISmsService
{
    private readonly Microsoft.Extensions.Logging.ILogger _logger;

    public SmsService(Microsoft.Extensions.Logging.ILogger logger)
    {
        _logger = logger;
    }

    public async Task<bool> SendSmsAsync(string phoneNumber, string message)
    {
        try
        {
            // In a real implementation, you would integrate with an SMS provider like Twilio
            // For now, we'll simulate the SMS sending
            _logger.Information("SMS sent to {PhoneNumber}: {Message}", phoneNumber, message);
            
            // Simulate async operation
            await Task.Delay(100);
            
            // Simulate success (in real implementation, check provider response)
            return true;
        }
        catch (Exception ex)
        {
            _logger.Error(ex, "Error sending SMS to {PhoneNumber}", phoneNumber);
            return false;
        }
    }
}

