# Makefile para Flutter - Automação de tarefas de desenvolvimento
# Uso: make <comando>

.PHONY: help clean get build test analyze format deps check-deps install-tools doctor setup dev release

# Variáveis
FLUTTER := flutter
DART := dart

# Cores para output
RED := \033[0;31m
GREEN := \033[0;32m
YELLOW := \033[1;33m
BLUE := \033[0;34m
NC := \033[0m # No Color

# Comando padrão
help:
	@echo "${BLUE}Flutter Project - Comandos disponíveis:${NC}"
	@echo ""
	@echo "${GREEN}Desenvolvimento:${NC}"
	@echo "  setup          - Configuração inicial completa"
	@echo "  get            - Instala dependências"
	@echo "  dev            - Roda app em modo debug"
	@echo "  clean          - Limpa cache e builds"
	@echo "  format         - Formata código"
	@echo ""
	@echo "${GREEN}Qualidade:${NC}"
	@echo "  analyze        - Análise estática"
	@echo "  test           - Executa testes"
	@echo "  check          - Análise completa + testes"
	@echo ""
	@echo "${GREEN}Build:${NC}"
	@echo "  build-apk      - Build APK release"
	@echo "  build-bundle   - Build App Bundle"
	@echo "  build-web      - Build para web"
	@echo ""
	@echo "${GREEN}Ferramentas:${NC}"
	@echo "  doctor         - Flutter doctor"
	@echo "  deps           - Mostra dependências"
	@echo "  outdated       - Verifica dependências desatualizadas"

# Configuração inicial
setup: clean install-tools get
	@echo "${GREEN}✅ Configuração inicial concluída!${NC}"

# Limpeza
clean:
	@echo "${YELLOW}🧹 Limpando projeto...${NC}"
	$(FLUTTER) clean
	$(DART) pub cache repair
	@echo "${GREEN}✅ Projeto limpo!${NC}"

# Instalar dependências
get:
	@echo "${YELLOW}📦 Instalando dependências...${NC}"
	$(FLUTTER) pub get
	@echo "${GREEN}✅ Dependências instaladas!${NC}"

# Rodar em modo debug
dev:
	@echo "${YELLOW}🚀 Iniciando app em modo debug...${NC}"
	$(FLUTTER) run --debug

# Formatação de código
format:
	@echo "${YELLOW}✨ Formatando código...${NC}"
	$(DART) format --set-exit-if-changed .
	@echo "${GREEN}✅ Código formatado!${NC}"

# Análise estática
analyze:
	@echo "${YELLOW}🔍 Executando análise estática...${NC}"
	$(FLUTTER) analyze
	@echo "${GREEN}✅ Análise concluída!${NC}"

# Testes
test:
	@echo "${YELLOW}🧪 Executando testes...${NC}"
	$(FLUTTER) test --coverage
	@echo "${GREEN}✅ Testes executados!${NC}"

# Verificação completa
check: format analyze test
	@echo "${GREEN}✅ Verificação completa finalizada!${NC}"

# Build APK
build-apk:
	@echo "${YELLOW}📱 Gerando APK de release...${NC}"
	$(FLUTTER) build apk --release
	@echo "${GREEN}✅ APK gerado em build/app/outputs/flutter-apk/app-release.apk${NC}"

# Build App Bundle
build-bundle:
	@echo "${YELLOW}📦 Gerando App Bundle...${NC}"
	$(FLUTTER) build appbundle --release
	@echo "${GREEN}✅ App Bundle gerado em build/app/outputs/bundle/release/app-release.aab${NC}"

# Build Web
build-web:
	@echo "${YELLOW}🌐 Gerando build web...${NC}"
	$(FLUTTER) build web --release
	@echo "${GREEN}✅ Build web gerado em build/web/${NC}"

# Flutter Doctor
doctor:
	@echo "${YELLOW}🩺 Executando Flutter Doctor...${NC}"
	$(FLUTTER) doctor -v

# Mostrar dependências
deps:
	@echo "${YELLOW}📋 Dependências do projeto:${NC}"
	$(FLUTTER) pub deps

# Verificar dependências desatualizadas
outdated:
	@echo "${YELLOW}📊 Verificando dependências desatualizadas...${NC}"
	$(FLUTTER) pub outdated

# Instalar ferramentas adicionais
install-tools:
	@echo "${YELLOW}🔧 Instalando ferramentas adicionais...${NC}"
	$(DART) pub global activate dart_code_metrics
	$(DART) pub global activate coverage
	@echo "${GREEN}✅ Ferramentas instaladas!${NC}"

# Gerar relatório de cobertura de testes
coverage: test
	@echo "${YELLOW}📈 Gerando relatório de cobertura...${NC}"
	genhtml coverage/lcov.info -o coverage/html
	@echo "${GREEN}✅ Relatório gerado em coverage/html/index.html${NC}"

# Upgrade do Flutter
upgrade:
	@echo "${YELLOW}⬆️  Atualizando Flutter...${NC}"
	$(FLUTTER) upgrade
	@echo "${GREEN}✅ Flutter atualizado!${NC}"

# Atualizar dependências
update-deps: get
	@echo "${YELLOW}🔄 Atualizando dependências...${NC}"
	$(FLUTTER) pub upgrade
	@echo "${GREEN}✅ Dependências atualizadas!${NC}"

# Build profile para análise de performance
build-profile:
	@echo "${YELLOW}⚡ Gerando build profile...${NC}"
	$(FLUTTER) build apk --profile
	@echo "${GREEN}✅ Build profile gerado!${NC}"

# Listar dispositivos conectados
devices:
	@echo "${YELLOW}📱 Dispositivos conectados:${NC}"
	$(FLUTTER) devices

# Executar em dispositivo específico
run-device:
	@echo "${YELLOW}📱 Dispositivos disponíveis:${NC}"
	@$(FLUTTER) devices
	@echo "${BLUE}Use: flutter run -d <device-id>${NC}"

# Instalar no dispositivo
install: build-apk
	@echo "${YELLOW}📲 Instalando APK...${NC}"
	adb install build/app/outputs/flutter-apk/app-release.apk
	@echo "${GREEN}✅ APK instalado!${NC}"

# Gerar ícones do app
icons:
	@echo "${YELLOW}🎨 Gerando ícones...${NC}"
	$(FLUTTER) pub run flutter_launcher_icons:main
	@echo "${GREEN}✅ Ícones gerados!${NC}"

# Performance check
perf: build-profile
	@echo "${YELLOW}⚡ Análise de performance disponível no build profile${NC}"

# CI/CD check - usado em pipelines
ci: format analyze test
	@echo "${GREEN}✅ Pipeline CI/CD passou!${NC}"