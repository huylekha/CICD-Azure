using MediatR;
using PaymentService.Services;
using Shared.Domain.Commands;

namespace PaymentService.Handlers;

public class TransferMoneyCommandHandler : IRequestHandler<TransferMoneyCommand, TransferMoneyResult>
{
    private readonly IPaymentService _paymentService;

    public TransferMoneyCommandHandler(IPaymentService paymentService)
    {
        _paymentService = paymentService;
    }

    public async Task<TransferMoneyResult> Handle(TransferMoneyCommand request, CancellationToken cancellationToken)
    {
        return await _paymentService.TransferMoneyAsync(request);
    }
}

