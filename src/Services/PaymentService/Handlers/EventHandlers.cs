using MassTransit;
using PaymentService.Services;
using Serilog;
using Shared.Domain.Events;
using Microsoft.Extensions.Logging;

namespace PaymentService.Handlers;

public class TransferRollbackRequestedHandler : IConsumer<TransferRollbackRequested>
{
    private readonly IPaymentService _paymentService;
    private readonly Microsoft.Extensions.Logging.ILogger _logger;

    public TransferRollbackRequestedHandler(IPaymentService paymentService, Microsoft.Extensions.Logging.ILogger logger)
    {
        _paymentService = paymentService;
        _logger = logger;
    }

    public async Task Consume(ConsumeContext<TransferRollbackRequested> context)
    {
        var message = context.Message;
        
        _logger.LogInformation("Processing transfer rollback request: {TransactionId}, Reason: {Reason}",
            message.TransactionId, message.RollbackReason);

        try
        {
            var rollbackCommand = new Shared.Domain.Commands.RollbackTransferCommand
            {
                TransactionId = message.TransactionId,
                Reason = message.RollbackReason,
                CorrelationId = message.CorrelationId
            };

            var result = await _paymentService.RollbackTransferAsync(rollbackCommand);

            if (!result.Success)
            {
                _logger.LogError("Failed to rollback transfer: {TransactionId}, Error: {Error}",
                    message.TransactionId, result.ErrorMessage);
            }
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error processing transfer rollback request: {TransactionId}", message.TransactionId);
            throw;
        }
    }
}

