using MediatR;
using PaymentService.Services;
using Shared.Domain.Queries;

namespace PaymentService.Handlers;

public class GetAccountQueryHandler : IRequestHandler<GetAccountQuery, GetAccountResult>
{
    private readonly IPaymentService _paymentService;

    public GetAccountQueryHandler(IPaymentService paymentService)
    {
        _paymentService = paymentService;
    }

    public async Task<GetAccountResult> Handle(GetAccountQuery request, CancellationToken cancellationToken)
    {
        return await _paymentService.GetAccountAsync(request);
    }
}

public class GetTransactionQueryHandler : IRequestHandler<GetTransactionQuery, GetTransactionResult>
{
    private readonly IPaymentService _paymentService;

    public GetTransactionQueryHandler(IPaymentService paymentService)
    {
        _paymentService = paymentService;
    }

    public async Task<GetTransactionResult> Handle(GetTransactionQuery request, CancellationToken cancellationToken)
    {
        return await _paymentService.GetTransactionAsync(request);
    }
}

public class GetAccountTransactionsQueryHandler : IRequestHandler<GetAccountTransactionsQuery, GetAccountTransactionsResult>
{
    private readonly IPaymentService _paymentService;

    public GetAccountTransactionsQueryHandler(IPaymentService paymentService)
    {
        _paymentService = paymentService;
    }

    public async Task<GetAccountTransactionsResult> Handle(GetAccountTransactionsQuery request, CancellationToken cancellationToken)
    {
        return await _paymentService.GetAccountTransactionsAsync(request);
    }
}

