import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../utils/app_logger.dart';

class HelpScreen extends StatefulWidget {
  const HelpScreen({super.key});

  @override
  State<HelpScreen> createState() => _HelpScreenState();
}

class _HelpScreenState extends State<HelpScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _expandedIndex = -1;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ajuda'),
        backgroundColor: Colors.green[700],
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.help), text: 'Guia'),
            Tab(icon: Icon(Icons.quiz), text: 'FAQ'),
            Tab(icon: Icon(Icons.video_library), text: 'Tutoriais'),
            Tab(icon: Icon(Icons.contact_support), text: 'Contato'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildGuideTab(),
          _buildFAQTab(),
          _buildTutorialsTab(),
          _buildContactTab(),
        ],
      ),
    );
  }

  Widget _buildGuideTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildWelcomeCard(),
          const SizedBox(height: 20),
          _buildFeatureCard(
            'Dashboard',
            'Visão geral da sua fazenda',
            Icons.dashboard,
            Colors.blue,
            [
              'Resumo do rebanho (total de vacas, vacas em lactação)',
              'Gráficos de produção de leite',
              'Indicadores de saúde do rebanho',
              'Ciclo reprodutivo das vacas',
            ],
          ),
          _buildFeatureCard(
            'Gestão de Vacas',
            'Cadastro e acompanhamento do rebanho',
            Icons.pets,
            Colors.brown,
            [
              'Cadastrar novas vacas com dados completos',
              'Acompanhar histórico de cada animal',
              'Controlar período de lactação',
              'Buscar vacas por nome ou ID',
            ],
          ),
          _buildFeatureCard(
            'Registro de Produção',
            'Controle diário da produção de leite',
            Icons.water_drop,
            Colors.cyan,
            [
              'Registrar produção diária de cada vaca',
              'Acompanhar histórico de produção',
              'Identificar quedas na produção',
              'Exportar dados para análise',
            ],
          ),
          _buildFeatureCard(
            'Alertas Inteligentes',
            'Notificações automáticas importantes',
            Icons.notifications,
            Colors.orange,
            [
              'Alertas de queda na produção',
              'Lembretes de vacinação',
              'Notificações de ciclo reprodutivo',
              'Alertas personalizáveis',
            ],
          ),
          _buildFeatureCard(
            'Relatórios',
            'Análises detalhadas da fazenda',
            Icons.analytics,
            Colors.purple,
            [
              'Relatórios de produção por período',
              'Análise de performance das vacas',
              'Gráficos interativos',
              'Exportação em PDF/Excel',
            ],
          ),
          _buildFeatureCard(
            'Gestão Financeira',
            'Controle de receitas e despesas',
            Icons.attach_money,
            Colors.green,
            [
              'Registro de vendas de leite',
              'Controle de despesas veterinárias',
              'Custos de alimentação e medicamentos',
              'Relatórios de lucro/prejuízo',
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFAQTab() {
    final faqItems = [
      {
        'question': 'Como cadastrar uma nova vaca?',
        'answer':
            'Vá para a aba "Vacas", clique no botão "+" no canto superior direito, preencha as informações básicas como nome, raça, idade e características da vaca, então salve.'
      },
      {
        'question': 'Como registrar a produção diária?',
        'answer':
            'Na aba "Produção", selecione a vaca, digite a quantidade de leite produzida e a data. O sistema salvará automaticamente o registro.'
      },
      {
        'question': 'Por que não recebo alertas?',
        'answer':
            'Verifique se as notificações estão habilitadas nas configurações do app e do seu dispositivo. Vá em Configurações > Alertas para personalizar os tipos de notificação.'
      },
      {
        'question': 'Como exportar relatórios?',
        'answer':
            'Na tela de Relatórios, selecione o período desejado e clique no ícone de compartilhamento ou download para exportar em PDF ou Excel.'
      },
      {
        'question': 'Posso usar o app offline?',
        'answer':
            'O app funciona melhor com conexão à internet. Alguns dados ficam em cache temporariamente, mas é recomendado usar com conexão para sincronização completa.'
      },
      {
        'question': 'Como fazer backup dos meus dados?',
        'answer':
            'Os dados são automaticamente salvos na nuvem. Em Configurações > Backup, você pode forçar um backup manual ou restaurar dados anteriores.'
      },
      {
        'question': 'O que significam as cores nos gráficos?',
        'answer':
            'Verde: produção normal/boa. Amarelo: atenção, possível queda. Vermelho: problema detectado, necessita ação imediata.'
      },
      {
        'question': 'Como alterar dados de uma vaca?',
        'answer':
            'Na lista de vacas, toque na vaca desejada, depois clique no ícone de edição (lápis) para modificar as informações.'
      },
    ];

    return SingleChildScrollView(
      child: ExpansionPanelList(
        expansionCallback: (panelIndex, isExpanded) {
          setState(() {
            _expandedIndex = isExpanded ? -1 : panelIndex;
          });
        },
        children: faqItems.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          return ExpansionPanel(
            headerBuilder: (context, isExpanded) {
              return ListTile(
                leading: const Icon(Icons.help_outline, color: Colors.green),
                title: Text(
                  item['question']!,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              );
            },
            body: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Text(
                item['answer']!,
                style: const TextStyle(fontSize: 14, height: 1.5),
              ),
            ),
            isExpanded: _expandedIndex == index,
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTutorialsTab() {
    final tutorials = [
      {
        'title': 'Primeiros Passos',
        'description': 'Como configurar o app pela primeira vez',
        'icon': Icons.play_circle_outline,
        'duration': '5 min',
        'url': 'https://youtube.com/tutorial1', // URL de exemplo
      },
      {
        'title': 'Cadastrando Vacas',
        'description': 'Tutorial completo sobre cadastro de animais',
        'icon': Icons.pets,
        'duration': '8 min',
        'url': 'https://youtube.com/tutorial2',
      },
      {
        'title': 'Registrando Produção',
        'description': 'Como registrar a produção diária de leite',
        'icon': Icons.water_drop,
        'duration': '6 min',
        'url': 'https://youtube.com/tutorial3',
      },
      {
        'title': 'Entendendo Relatórios',
        'description': 'Como interpretar gráficos e relatórios',
        'icon': Icons.analytics,
        'duration': '12 min',
        'url': 'https://youtube.com/tutorial4',
      },
      {
        'title': 'Configurando Alertas',
        'description': 'Personalize notificações para sua fazenda',
        'icon': Icons.notifications_active,
        'duration': '7 min',
        'url': 'https://youtube.com/tutorial5',
      },
    ];

    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: tutorials.length,
      itemBuilder: (context, index) {
        final tutorial = tutorials[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.red[100],
              child: Icon(
                tutorial['icon'] as IconData,
                color: Colors.red[700],
              ),
            ),
            title: Text(
              tutorial['title'] as String,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tutorial['description'] as String),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.access_time, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      tutorial['duration'] as String,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            trailing: const Icon(Icons.play_arrow, color: Colors.red),
            onTap: () => _launchTutorial(tutorial['url'] as String),
          ),
        );
      },
    );
  }

  Widget _buildContactTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  const Icon(
                    Icons.support_agent,
                    size: 60,
                    color: Colors.green,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Precisa de Ajuda?',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Nossa equipe está pronta para ajudar você!',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          _buildContactOption(
            icon: Icons.email,
            title: 'Email',
            subtitle: 'suporte@pleite.com.br',
            color: Colors.blue,
            onTap: () => _launchEmail('suporte@pleite.com.br'),
          ),
          _buildContactOption(
            icon: Icons.phone,
            title: 'Telefone',
            subtitle: '(11) 99999-9999',
            color: Colors.green,
            onTap: () => _launchPhone('11999999999'),
          ),
          _buildContactOption(
            icon: Icons.chat,
            title: 'WhatsApp',
            subtitle: 'Chat direto com suporte',
            color: Colors.green[700]!,
            onTap: () => _launchWhatsApp('11999999999'),
          ),
          _buildContactOption(
            icon: Icons.language,
            title: 'Site',
            subtitle: 'www.pleite.com.br',
            color: Colors.indigo,
            onTap: () => _launchUrl('https://pleite.com.br'),
          ),
          const SizedBox(height: 30),
          Card(
            color: Colors.orange[50],
            child: const Padding(
              padding: EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Icon(Icons.schedule, color: Colors.orange, size: 32),
                  SizedBox(height: 8),
                  Text(
                    'Horário de Atendimento',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Segunda a Sexta: 8h às 18h\nSábado: 8h às 12h',
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeCard() {
    return Card(
      elevation: 4,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [Colors.green[700]!, Colors.green[500]!],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.agriculture, color: Colors.white, size: 32),
                SizedBox(width: 12),
                Text(
                  'Bem-vindo ao Leite+!',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            Text(
              'Seu assistente completo para gestão de fazenda leiteira. Controle seu rebanho, monitore a produção e maximize seus resultados.',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureCard(String title, String description, IconData icon,
      Color color, List<String> features) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        description,
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...features.map(
              (feature) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: Colors.green,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        feature,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.1),
          child: Icon(icon, color: color),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }

  Future<void> _launchTutorial(String url) async {
    try {
      // Mostrar diálogo explicativo já que não temos url_launcher
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Tutorial'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Este tutorial está disponível em:'),
                const SizedBox(height: 8),
                SelectableText(
                  url,
                  style: const TextStyle(
                    color: Colors.blue,
                    decoration: TextDecoration.underline,
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: url));
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Link copiado para a área de transferência'),
                      ),
                    );
                  },
                  child: const Text('Copiar Link'),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Fechar'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      AppLogger.error('Erro ao abrir tutorial', e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Não foi possível abrir o tutorial'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _launchEmail(String email) async {
    _showContactDialog('Email', email, 'mailto:$email');
  }

  Future<void> _launchPhone(String phone) async {
    _showContactDialog('Telefone', phone, 'tel:$phone');
  }

  Future<void> _launchWhatsApp(String phone) async {
    _showContactDialog('WhatsApp', phone, 'https://wa.me/$phone');
  }

  Future<void> _launchUrl(String url) async {
    _showContactDialog('Site', url, url);
  }

  void _showContactDialog(String type, String display, String link) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(type),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Entre em contato através de:'),
            const SizedBox(height: 8),
            SelectableText(
              display,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: link));
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('$type copiado para a área de transferência'),
                      ),
                    );
                  },
                  child: const Text('Copiar'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: display));
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Informação copiada'),
                      ),
                    );
                  },
                  child: const Text('Copiar Info'),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }
}