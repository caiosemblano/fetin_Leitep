import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/user_service.dart';
import '../services/finance_service.dart';
import 'package:intl/intl.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import '../widgets/upgrade_prompt_widget.dart';

class FinanceiroScreen extends StatefulWidget {
  const FinanceiroScreen({super.key});

  @override
  State<FinanceiroScreen> createState() => _FinanceiroScreenState();
}

class _FinanceiroScreenState extends State<FinanceiroScreen> {
  final FinanceService _financeService = FinanceService();
  bool _isSaving = false;
  @override
  Widget build(BuildContext context) {
    final subscription = Provider.of<UserSubscription>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestão Financeira'),
        backgroundColor: Colors.teal,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed: _adicionarTransacao,
          ),
        ],
      ),
      body: subscription.hasIntermediateAccess
          ? _buildAdvancedFinanceView()
          : _buildBasicFinanceView(),
    );
  }

  /// Visão para planos Intermediário e Premium
  Widget _buildAdvancedFinanceView() {
    return StreamBuilder<List<FinancialTransaction>>(
      stream: _financeService.getTransactionsStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 60),
                  const SizedBox(height: 16),
                  const Text(
                    'Ocorreu um erro',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'Não foi possível carregar os dados financeiros. Tente novamente mais tarde.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          );
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.receipt_long, size: 80, color: Colors.grey[400]),
                const SizedBox(height: 16),
                const Text(
                  'Nenhuma transação registrada.',
                  style: TextStyle(fontSize: 18),
                ),
                Text(
                  'Clique no botão "+" para começar.',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
          );
        }

        final transactions = snapshot.data!;
        final receitaTotal = transactions
            .where((t) => t.type == 'receita')
            .fold(0.0, (sum, item) => sum + item.amount);
        final despesaTotal = transactions
            .where((t) => t.type == 'despesa')
            .fold(0.0, (sum, item) => sum + item.amount);
        final resultado = receitaTotal - despesaTotal;

        return Column(
          children: [
            // Cards de resumo financeiro
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Expanded(
                    child: _buildFinanceCard(
                      'Receita',
                      receitaTotal,
                      Colors.green,
                      Icons.trending_up,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildFinanceCard(
                      'Despesas',
                      despesaTotal,
                      Colors.red,
                      Icons.trending_down,
                    ),
                  ),
                ],
              ),
            ),
            // Lucro/Prejuízo
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Resultado:', style: TextStyle(fontSize: 18)),
                    Text(
                      NumberFormat.currency(
                        locale: 'pt_BR',
                        symbol: r'R$',
                      ).format(resultado),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: resultado >= 0 ? Colors.green : Colors.red,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const Divider(height: 32),
            const Text(
              'Transações Recentes',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: transactions.length,
                itemBuilder: (context, index) {
                  final transacao = transactions[index];
                  return Slidable(
                    key: ValueKey(transacao.id),
                    endActionPane: ActionPane(
                      motion: const DrawerMotion(),
                      children: [
                        SlidableAction(
                          onPressed: (_) =>
                              _adicionarTransacao(transacao: transacao),
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          icon: Icons.edit,
                          label: 'Editar',
                        ),
                        SlidableAction(
                          onPressed: (_) => _deletarTransacao(transacao),
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          icon: Icons.delete,
                          label: 'Excluir',
                        ),
                      ],
                    ),
                    child: ListTile(
                      leading: Icon(
                        transacao.type == 'receita'
                            ? Icons.arrow_upward
                            : Icons.arrow_downward,
                        color: transacao.type == 'receita'
                            ? Colors.green
                            : Colors.red,
                      ),
                      title: Text(transacao.description),
                      subtitle: Text(
                        DateFormat('dd/MM/yyyy').format(transacao.date),
                      ),
                      trailing: Text(
                        NumberFormat.currency(
                          locale: 'pt_BR',
                          symbol: r'R$',
                        ).format(transacao.amount),
                        style: TextStyle(
                          color: transacao.type == 'receita'
                              ? Colors.green
                              : Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  /// Visão para o plano Básico, com um incentivo para upgrade.
  Widget _buildBasicFinanceView() {
    return const UpgradePromptWidget(
      featureName: 'Gestão Financeira Detalhada',
      description:
          'Tenha acesso a relatórios de receita, despesas, lucro e muito mais para tomar as melhores decisões para sua fazenda.',
      requiredPlan: 'Intermediário',
    );
  }

  Widget _buildFinanceCard(
    String title,
    double value,
    Color color,
    IconData icon,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(title, style: const TextStyle(fontSize: 16)),
            Text(
              NumberFormat.currency(
                locale: 'pt_BR',
                symbol: r'R$',
              ).format(value),
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _adicionarTransacao({FinancialTransaction? transacao}) {
    final isEditing = transacao != null;
    final formKey = GlobalKey<FormState>();

    final descriptionController = TextEditingController(
      text: isEditing ? transacao.description : '',
    );
    final amountController = TextEditingController(
      text: isEditing ? transacao.amount.toString().replaceAll('.', ',') : '',
    );
    String type = isEditing ? transacao.type : 'despesa';

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(
                isEditing ? 'Editar Transação' : 'Adicionar Transação',
              ),
              content: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: descriptionController,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: 'Descrição',
                        ),
                        validator: (value) => value == null || value.isEmpty
                            ? 'Campo obrigatório'
                            : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: amountController,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: r'Valor (R$)',
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Campo obrigatório';
                          }
                          final amount = double.tryParse(
                            value.replaceAll(',', '.'),
                          );
                          if (amount == null) {
                            return 'Valor inválido';
                          }
                          if (amount <= 0) {
                            return 'O valor deve ser maior que zero';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: type,
                        items: const [
                          DropdownMenuItem(
                            value: 'despesa',
                            child: Text('Despesa'),
                          ),
                          DropdownMenuItem(
                            value: 'receita',
                            child: Text('Receita'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => type = value);
                          }
                        },
                        decoration: const InputDecoration(
                          labelText: 'Tipo',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: _isSaving
                      ? null
                      : () async {
                          if (formKey.currentState!.validate()) {
                            setState(() => _isSaving = true);
                            try {
                              final amount = double.parse(
                                amountController.text.replaceAll(',', '.'),
                              );

                              if (isEditing) {
                                await _financeService.updateTransaction(
                                  transactionId: transacao.id,
                                  description: descriptionController.text,
                                  amount: amount,
                                  type: type,
                                  date:
                                      transacao.date, // Mantém a data original
                                );
                              } else {
                                await _financeService.addTransaction(
                                  description: descriptionController.text,
                                  amount: amount,
                                  type: type,
                                  date: DateTime.now(),
                                );
                              }
                              if (mounted) {
                                Navigator.of(context).pop();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Transação salva!'),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              }
                            } catch (e) {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Erro ao salvar: $e'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            } finally {
                              if (mounted) {
                                setState(() => _isSaving = false);
                              }
                            }
                          }
                        },
                  child: _isSaving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : Text(isEditing ? 'Atualizar' : 'Salvar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _deletarTransacao(FinancialTransaction transacao) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Exclusão'),
        content: Text(
          'Deseja realmente excluir a transação "${transacao.description}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await _financeService.deleteTransaction(transacao.id);
                if (mounted) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Transação excluída!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Erro ao excluir: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
  }
}
