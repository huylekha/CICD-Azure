using MediatR;
using PaymentService.Services;
using Shared.Domain.Commands;

namespace PaymentService.Handlers;

public class RollbackTransferCommandHandler : IRequestHandler<RollbackTransferCommand, RollbackTransferResult>
{
    private readonly IPaymentService _paymentService;

    public RollbackTransferCommandHandler(IPaymentService paymentService)
    {
        _paymentService = paymentService;
    }

    public async Task<RollbackTransferResult> Handle(RollbackTransferCommand request, CancellationToken cancellationToken)
    {
        return await _paymentService.RollbackTransferAsync(request);
    }
}

