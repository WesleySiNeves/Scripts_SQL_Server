// Configurações globais
const CONFIG = {
    animationDuration: 300,
    typewriterSpeed: 50,
    particleCount: 50
};

// Inicialização quando o DOM estiver carregado
document.addEventListener('DOMContentLoaded', function() {
    initializeApp();
});

function initializeApp() {
    initializeNavigation();
    initializeAnimations();
    initializeSQLEditor();
    initializeExercises();
    initializeInteractiveElements();
    initializeParticleSystem();
    initializeTypewriter();
    initializeScrollEffects();
    initializeDatabaseVisualization();
}

// ==================== NAVEGAÇÃO ====================
function initializeNavigation() {
    const navbar = document.querySelector('.navbar');
    const navLinks = document.querySelectorAll('.nav-link');
    
    // Efeito de scroll na navbar
    window.addEventListener('scroll', () => {
        if (window.scrollY > 100) {
            navbar.style.background = 'rgba(255, 255, 255, 0.98)';
            navbar.style.boxShadow = '0 4px 30px rgba(0, 0, 0, 0.15)';
        } else {
            navbar.style.background = 'rgba(255, 255, 255, 0.95)';
            navbar.style.boxShadow = '0 2px 20px rgba(0, 0, 0, 0.1)';
        }
    });
    
    // Scroll suave para seções
    navLinks.forEach(link => {
        link.addEventListener('click', (e) => {
            e.preventDefault();
            const targetId = link.getAttribute('href').substring(1);
            const targetSection = document.getElementById(targetId);
            
            if (targetSection) {
                const offsetTop = targetSection.offsetTop - 80;
                window.scrollTo({
                    top: offsetTop,
                    behavior: 'smooth'
                });
            }
        });
    });
}

// ==================== ANIMAÇÕES ====================
function initializeAnimations() {
    // Intersection Observer para animações de entrada
    const observerOptions = {
        threshold: 0.1,
        rootMargin: '0px 0px -50px 0px'
    };
    
    const observer = new IntersectionObserver((entries) => {
        entries.forEach(entry => {
            if (entry.isIntersecting) {
                entry.target.style.opacity = '1';
                entry.target.style.transform = 'translateY(0)';
            }
        });
    }, observerOptions);
    
    // Observar elementos para animação
    const animatedElements = document.querySelectorAll('.timeline-item, .concept-card, .version-card, .exercise-card');
    animatedElements.forEach(el => {
        el.style.opacity = '0';
        el.style.transform = 'translateY(30px)';
        el.style.transition = 'all 0.6s ease-out';
        observer.observe(el);
    });
}

// ==================== EDITOR SQL ====================
function initializeSQLEditor() {
    const sqlInput = document.getElementById('sql-input');
    const runButton = document.querySelector('.run-button');
    const resultsContent = document.querySelector('.results-content');
    
    // Exemplo de queries pré-definidas
    const sampleQueries = {
        'tipos-numericos': `-- Exemplos de tipos numéricos
DECLARE @inteiro INT = 42;
DECLARE @decimal DECIMAL(10,2) = 123.45;
DECLARE @float FLOAT = 3.14159;

SELECT 
    @inteiro AS Inteiro,
    @decimal AS Decimal,
    @float AS Float;`,
        
        'tipos-texto': `-- Exemplos de tipos de texto
DECLARE @varchar VARCHAR(50) = 'SQL Server';
DECLARE @nvarchar NVARCHAR(50) = N'Programação';
DECLARE @char CHAR(10) = 'TSQL';

SELECT 
    @varchar AS Varchar,
    @nvarchar AS NVarchar,
    @char AS Char,
    LEN(@varchar) AS TamanhoVarchar;`,
        
        'tipos-data': `-- Exemplos de tipos de data
DECLARE @data DATE = '2024-01-15';
DECLARE @datetime DATETIME = '2024-01-15 14:30:00';
DECLARE @datetime2 DATETIME2 = '2024-01-15 14:30:00.123';
DECLARE @time TIME = '14:30:00';

SELECT 
    @data AS Data,
    @datetime AS DateTime,
    @datetime2 AS DateTime2,
    @time AS Time;`
    };
    
    // Syntax highlighting simples
    sqlInput.addEventListener('input', function() {
        // Aqui poderia implementar syntax highlighting mais avançado
        // Por simplicidade, apenas mudamos a cor de palavras-chave
    });
    
    // Executar query (simulado)
    runButton.addEventListener('click', function() {
        const query = sqlInput.value.trim();
        
        if (!query) {
            showResults('Por favor, digite uma query SQL.', 'error');
            return;
        }
        
        // Animação de loading
        runButton.textContent = 'Executando...';
        runButton.disabled = true;
        
        setTimeout(() => {
            simulateQueryExecution(query);
            runButton.textContent = 'Executar';
            runButton.disabled = false;
        }, 1000);
    });
    
    // Carregar query de exemplo
    window.loadSampleQuery = function(type) {
        if (sampleQueries[type]) {
            sqlInput.value = sampleQueries[type];
            typewriterEffect(sqlInput, sampleQueries[type]);
        }
    };
    
    function simulateQueryExecution(query) {
        const lowerQuery = query.toLowerCase();
        
        if (lowerQuery.includes('select')) {
            showResults(generateSampleResults(query), 'success');
        } else if (lowerQuery.includes('declare')) {
            showResults('Variáveis declaradas com sucesso!', 'success');
        } else {
            showResults('Query executada com sucesso!', 'success');
        }
    }
    
    function generateSampleResults(query) {
        const results = {
            'tipos-numericos': [
                { Inteiro: 42, Decimal: 123.45, Float: 3.14159 }
            ],
            'tipos-texto': [
                { Varchar: 'SQL Server', NVarchar: 'Programação', Char: 'TSQL      ', TamanhoVarchar: 10 }
            ],
            'tipos-data': [
                { 
                    Data: '2024-01-15', 
                    DateTime: '2024-01-15 14:30:00.000', 
                    DateTime2: '2024-01-15 14:30:00.1230000',
                    Time: '14:30:00'
                }
            ]
        };
        
        // Detectar tipo de query
        const lowerQuery = query.toLowerCase();
        if (lowerQuery.includes('inteiro') || lowerQuery.includes('decimal') || lowerQuery.includes('float')) {
            return createResultsTable(results['tipos-numericos']);
        } else if (lowerQuery.includes('varchar') || lowerQuery.includes('char')) {
            return createResultsTable(results['tipos-texto']);
        } else if (lowerQuery.includes('date') || lowerQuery.includes('time')) {
            return createResultsTable(results['tipos-data']);
        }
        
        return 'Query executada com sucesso! (Resultados simulados)';
    }
    
    function createResultsTable(data) {
        if (!data || data.length === 0) return 'Nenhum resultado encontrado.';
        
        const headers = Object.keys(data[0]);
        let html = '<table class="demo-table"><thead><tr>';
        
        headers.forEach(header => {
            html += `<th>${header}</th>`;
        });
        
        html += '</tr></thead><tbody>';
        
        data.forEach(row => {
            html += '<tr>';
            headers.forEach(header => {
                html += `<td>${row[header]}</td>`;
            });
            html += '</tr>';
        });
        
        html += '</tbody></table>';
        return html;
    }
    
    function showResults(content, type = 'success') {
        resultsContent.innerHTML = '';
        
        if (type === 'error') {
            resultsContent.innerHTML = `<div style="color: #ef4444; padding: 1rem; background: #fef2f2; border-radius: 8px; border: 1px solid #fecaca;">${content}</div>`;
        } else {
            resultsContent.innerHTML = content;
        }
        
        // Animação de fade in
        resultsContent.style.opacity = '0';
        setTimeout(() => {
            resultsContent.style.opacity = '1';
        }, 100);
    }
}

// ==================== EXERCÍCIOS ====================
function initializeExercises() {
    const exercises = {
        'basico': {
            title: 'Exercício Básico',
            description: 'Declare variáveis de diferentes tipos e exiba seus valores.',
            solution: `DECLARE @nome VARCHAR(50) = 'João Silva';
DECLARE @idade INT = 30;
DECLARE @salario DECIMAL(10,2) = 5500.00;
DECLARE @ativo BIT = 1;

SELECT 
    @nome AS Nome,
    @idade AS Idade,
    @salario AS Salario,
    @ativo AS Ativo;`
        },
        'intermediario': {
            title: 'Exercício Intermediário',
            description: 'Trabalhe com datas e funções de manipulação.',
            solution: `DECLARE @dataAtual DATETIME = GETDATE();
DECLARE @dataNascimento DATE = '1990-05-15';

SELECT 
    @dataAtual AS DataAtual,
    @dataNascimento AS DataNascimento,
    DATEDIFF(YEAR, @dataNascimento, @dataAtual) AS Idade,
    DATEADD(YEAR, 1, @dataAtual) AS ProximoAno;`
        },
        'avancado': {
            title: 'Exercício Avançado',
            description: 'Combine diferentes tipos de dados em uma consulta complexa.',
            solution: `DECLARE @produto NVARCHAR(100) = N'Notebook Dell';
DECLARE @preco MONEY = 2500.00;
DECLARE @desconto FLOAT = 0.15;
DECLARE @dataVenda DATETIME2 = '2024-01-15 10:30:00';

SELECT 
    @produto AS Produto,
    @preco AS PrecoOriginal,
    @preco * @desconto AS ValorDesconto,
    @preco * (1 - @desconto) AS PrecoFinal,
    FORMAT(@dataVenda, 'dd/MM/yyyy HH:mm') AS DataVendaFormatada;`
        }
    };
    
    window.startExercise = function(level) {
        const exercise = exercises[level];
        if (exercise) {
            showExerciseModal(exercise);
        }
    };
    
    function showExerciseModal(exercise) {
        const modal = createModal(exercise);
        document.body.appendChild(modal);
        
        // Animação de entrada
        setTimeout(() => {
            modal.style.opacity = '1';
            modal.querySelector('.modal-content').style.transform = 'scale(1)';
        }, 10);
    }
    
    function createModal(exercise) {
        const modal = document.createElement('div');
        modal.className = 'exercise-modal';
        modal.style.cssText = `
            position: fixed;
            top: 0;
            left: 0;
            width: 100%;
            height: 100%;
            background: rgba(0, 0, 0, 0.8);
            display: flex;
            justify-content: center;
            align-items: center;
            z-index: 10000;
            opacity: 0;
            transition: opacity 0.3s ease;
        `;
        
        modal.innerHTML = `
            <div class="modal-content" style="
                background: white;
                padding: 2rem;
                border-radius: 15px;
                max-width: 600px;
                width: 90%;
                max-height: 80vh;
                overflow-y: auto;
                transform: scale(0.8);
                transition: transform 0.3s ease;
            ">
                <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 1rem;">
                    <h3 style="color: #1f2937; margin: 0;">${exercise.title}</h3>
                    <button onclick="closeModal(this)" style="
                        background: none;
                        border: none;
                        font-size: 1.5rem;
                        cursor: pointer;
                        color: #6b7280;
                    ">&times;</button>
                </div>
                <p style="color: #6b7280; margin-bottom: 2rem;">${exercise.description}</p>
                <div style="margin-bottom: 1rem;">
                    <button onclick="showSolution(this)" style="
                        background: linear-gradient(45deg, #10b981, #059669);
                        color: white;
                        border: none;
                        padding: 0.75rem 1.5rem;
                        border-radius: 8px;
                        cursor: pointer;
                        font-weight: 500;
                        margin-right: 1rem;
                    ">Ver Solução</button>
                    <button onclick="copySolution(this)" style="
                        background: linear-gradient(45deg, #4f46e5, #7c3aed);
                        color: white;
                        border: none;
                        padding: 0.75rem 1.5rem;
                        border-radius: 8px;
                        cursor: pointer;
                        font-weight: 500;
                    ">Copiar para Editor</button>
                </div>
                <div class="solution-container" style="display: none;">
                    <h4 style="color: #1f2937; margin-bottom: 1rem;">Solução:</h4>
                    <pre style="
                        background: #1f2937;
                        color: #e5e7eb;
                        padding: 1rem;
                        border-radius: 8px;
                        overflow-x: auto;
                        font-family: 'Courier New', monospace;
                        font-size: 0.9rem;
                        line-height: 1.4;
                    ">${exercise.solution}</pre>
                </div>
            </div>
        `;
        
        // Event listeners
        modal.addEventListener('click', (e) => {
            if (e.target === modal) {
                closeModal(modal.querySelector('button'));
            }
        });
        
        return modal;
    }
    
    window.closeModal = function(button) {
        const modal = button.closest('.exercise-modal');
        modal.style.opacity = '0';
        setTimeout(() => {
            modal.remove();
        }, 300);
    };
    
    window.showSolution = function(button) {
        const container = button.closest('.modal-content').querySelector('.solution-container');
        container.style.display = 'block';
        button.textContent = 'Solução Exibida';
        button.disabled = true;
    };
    
    window.copySolution = function(button) {
        const solution = button.closest('.modal-content').querySelector('pre').textContent;
        const sqlInput = document.getElementById('sql-input');
        sqlInput.value = solution;
        
        // Feedback visual
        const originalText = button.textContent;
        button.textContent = 'Copiado!';
        button.style.background = 'linear-gradient(45deg, #10b981, #059669)';
        
        setTimeout(() => {
            button.textContent = originalText;
            button.style.background = 'linear-gradient(45deg, #4f46e5, #7c3aed)';
        }, 2000);
        
        closeModal(button);
    };
}

// ==================== ELEMENTOS INTERATIVOS ====================
function initializeInteractiveElements() {
    // Hover effects para cards de versão
    const versionCards = document.querySelectorAll('.version-card');
    versionCards.forEach(card => {
        card.addEventListener('mouseenter', () => {
            card.style.transform = 'translateY(-10px) scale(1.02)';
        });
        
        card.addEventListener('mouseleave', () => {
            card.style.transform = 'translateY(0) scale(1)';
        });
    });
    
    // Interação com elementos da timeline
    const timelineItems = document.querySelectorAll('.timeline-item');
    timelineItems.forEach((item, index) => {
        item.addEventListener('click', () => {
            // Destacar item selecionado
            timelineItems.forEach(ti => ti.classList.remove('active'));
            item.classList.add('active');
            
            // Adicionar efeito visual
            const icon = item.querySelector('.timeline-icon');
            icon.style.transform = 'scale(1.2)';
            setTimeout(() => {
                icon.style.transform = 'scale(1)';
            }, 200);
        });
    });
    
    // Interação com arquitetura
    const archLayers = document.querySelectorAll('.arch-layer');
    archLayers.forEach(layer => {
        layer.addEventListener('click', () => {
            const layerType = layer.getAttribute('data-layer');
            showLayerInfo(layerType, layer);
        });
    });
    
    function showLayerInfo(layerType, element) {
        const info = {
            'aplicacao': 'Camada de Aplicação: Interface do usuário e lógica de apresentação',
            'servicos': 'Camada de Serviços: APIs, web services e lógica de negócio',
            'motor': 'Motor de Banco: SQL Server Engine, processamento de queries',
            'armazenamento': 'Armazenamento: Arquivos de dados, logs e backups'
        };
        
        // Criar tooltip
        const tooltip = document.createElement('div');
        tooltip.className = 'layer-tooltip';
        tooltip.textContent = info[layerType];
        tooltip.style.cssText = `
            position: absolute;
            background: #1f2937;
            color: white;
            padding: 1rem;
            border-radius: 8px;
            font-size: 0.9rem;
            max-width: 300px;
            z-index: 1000;
            box-shadow: 0 4px 15px rgba(0, 0, 0, 0.3);
            opacity: 0;
            transition: opacity 0.3s ease;
        `;
        
        document.body.appendChild(tooltip);
        
        // Posicionar tooltip
        const rect = element.getBoundingClientRect();
        tooltip.style.left = rect.right + 10 + 'px';
        tooltip.style.top = rect.top + 'px';
        
        // Mostrar tooltip
        setTimeout(() => {
            tooltip.style.opacity = '1';
        }, 10);
        
        // Remover tooltip após 3 segundos
        setTimeout(() => {
            tooltip.style.opacity = '0';
            setTimeout(() => {
                tooltip.remove();
            }, 300);
        }, 3000);
    }
}

// ==================== SISTEMA DE PARTÍCULAS ====================
function initializeParticleSystem() {
    const hero = document.querySelector('.hero');
    const particleContainer = document.createElement('div');
    particleContainer.className = 'particle-container';
    particleContainer.style.cssText = `
        position: absolute;
        top: 0;
        left: 0;
        width: 100%;
        height: 100%;
        pointer-events: none;
        overflow: hidden;
    `;
    
    hero.appendChild(particleContainer);
    
    // Criar partículas
    for (let i = 0; i < CONFIG.particleCount; i++) {
        createParticle(particleContainer);
    }
    
    function createParticle(container) {
        const particle = document.createElement('div');
        particle.className = 'particle';
        
        const size = Math.random() * 4 + 2;
        const x = Math.random() * 100;
        const duration = Math.random() * 20 + 10;
        const delay = Math.random() * 20;
        
        particle.style.cssText = `
            position: absolute;
            width: ${size}px;
            height: ${size}px;
            background: rgba(255, 255, 255, 0.6);
            border-radius: 50%;
            left: ${x}%;
            animation: particleFloat ${duration}s linear infinite;
            animation-delay: ${delay}s;
        `;
        
        container.appendChild(particle);
    }
    
    // Adicionar CSS para animação das partículas
    const style = document.createElement('style');
    style.textContent = `
        @keyframes particleFloat {
            0% {
                transform: translateY(100vh) rotate(0deg);
                opacity: 0;
            }
            10% {
                opacity: 1;
            }
            90% {
                opacity: 1;
            }
            100% {
                transform: translateY(-100px) rotate(360deg);
                opacity: 0;
            }
        }
    `;
    document.head.appendChild(style);
}

// ==================== EFEITO TYPEWRITER ====================
function initializeTypewriter() {
    const heroTitle = document.querySelector('.hero-title');
    const originalText = heroTitle.textContent;
    
    // Limpar texto inicial
    heroTitle.textContent = '';
    
    // Efeito typewriter
    setTimeout(() => {
        typewriterEffect(heroTitle, originalText);
    }, 1000);
}

function typewriterEffect(element, text, speed = CONFIG.typewriterSpeed) {
    let i = 0;
    element.textContent = '';
    
    const timer = setInterval(() => {
        if (i < text.length) {
            element.textContent += text.charAt(i);
            i++;
        } else {
            clearInterval(timer);
        }
    }, speed);
}

// ==================== EFEITOS DE SCROLL ====================
function initializeScrollEffects() {
    let ticking = false;
    
    window.addEventListener('scroll', () => {
        if (!ticking) {
            requestAnimationFrame(updateScrollEffects);
            ticking = true;
        }
    });
    
    function updateScrollEffects() {
        const scrolled = window.pageYOffset;
        const parallaxElements = document.querySelectorAll('.hero');
        
        parallaxElements.forEach(element => {
            const speed = 0.5;
            element.style.transform = `translateY(${scrolled * speed}px)`;
        });
        
        ticking = false;
    }
    
    // Indicador de progresso de leitura
    const progressBar = document.createElement('div');
    progressBar.style.cssText = `
        position: fixed;
        top: 0;
        left: 0;
        width: 0%;
        height: 3px;
        background: linear-gradient(45deg, #4f46e5, #7c3aed);
        z-index: 10001;
        transition: width 0.1s ease;
    `;
    document.body.appendChild(progressBar);
    
    window.addEventListener('scroll', () => {
        const scrollTop = window.pageYOffset;
        const docHeight = document.body.scrollHeight - window.innerHeight;
        const scrollPercent = (scrollTop / docHeight) * 100;
        progressBar.style.width = scrollPercent + '%';
    });
}

// ==================== VISUALIZAÇÃO DO BANCO DE DADOS ====================
function initializeDatabaseVisualization() {
    const serverUnits = document.querySelectorAll('.server-unit');
    
    // Ativar unidades de servidor em sequência
    serverUnits.forEach((unit, index) => {
        setTimeout(() => {
            unit.classList.add('active');
        }, index * 1000);
    });
    
    // Ciclo de ativação contínua
    setInterval(() => {
        serverUnits.forEach((unit, index) => {
            setTimeout(() => {
                unit.classList.remove('active');
                setTimeout(() => {
                    unit.classList.add('active');
                }, 200);
            }, index * 500);
        });
    }, 8000);
}

// ==================== UTILITÁRIOS ====================
function debounce(func, wait) {
    let timeout;
    return function executedFunction(...args) {
        const later = () => {
            clearTimeout(timeout);
            func(...args);
        };
        clearTimeout(timeout);
        timeout = setTimeout(later, wait);
    };
}

function throttle(func, limit) {
    let inThrottle;
    return function() {
        const args = arguments;
        const context = this;
        if (!inThrottle) {
            func.apply(context, args);
            inThrottle = true;
            setTimeout(() => inThrottle = false, limit);
        }
    };
}

// ==================== FUNÇÕES GLOBAIS ====================
// Função para carregar próximo módulo
window.loadNextModule = function() {
    alert('Próximo módulo: Comandos Básicos do T-SQL\n\nEm breve você aprenderá sobre:\n• SELECT, INSERT, UPDATE, DELETE\n• Cláusulas WHERE, ORDER BY, GROUP BY\n• Joins e subconsultas\n• Funções agregadas');
};

// Função para mostrar informações sobre versões
window.showVersionInfo = function(version) {
    const info = {
        'express': {
            title: 'SQL Server Express',
            description: 'Versão gratuita ideal para desenvolvimento e aplicações pequenas.',
            features: ['Até 10 GB de dados', 'Até 1 GB de RAM', 'Até 4 núcleos de CPU', 'Sem SQL Agent']
        },
        'standard': {
            title: 'SQL Server Standard',
            description: 'Versão comercial para aplicações de médio porte.',
            features: ['Sem limite de dados', 'Até 128 GB de RAM', 'Até 24 núcleos de CPU', 'Inclui SQL Agent']
        },
        'enterprise': {
            title: 'SQL Server Enterprise',
            description: 'Versão premium com todos os recursos avançados.',
            features: ['Sem limites', 'RAM ilimitada', 'CPU ilimitada', 'Recursos avançados de BI']
        }
    };
    
    const versionInfo = info[version];
    if (versionInfo) {
        alert(`${versionInfo.title}\n\n${versionInfo.description}\n\nCaracterísticas:\n${versionInfo.features.map(f => '• ' + f).join('\n')}`);
    }
};

// Função para demonstrar conceitos
window.demonstrateConcept = function(concept) {
    const demonstrations = {
        'tabelas': () => {
            alert('Demonstração: Tabelas\n\nUma tabela é uma estrutura que organiza dados em linhas e colunas.\n\nExemplo:\nTabela "Funcionarios"\n- ID (chave primária)\n- Nome\n- Cargo\n- Salário\n- Data de Admissão');
        },
        'chaves': () => {
            alert('Demonstração: Chaves\n\nChave Primária: Identifica unicamente cada linha\nChave Estrangeira: Referencia a chave primária de outra tabela\n\nExemplo:\nTabela Pedidos:\n- PedidoID (PK)\n- ClienteID (FK para Clientes.ClienteID)\n- Data\n- Valor');
        },
        'indices': () => {
            alert('Demonstração: Índices\n\nÍndices aceleram consultas criando estruturas de busca otimizadas.\n\nTipos:\n• Clustered: Organiza fisicamente os dados\n• Non-clustered: Ponteiros para os dados\n\nExemplo: Índice no campo "Email" para busca rápida');
        },
        'schemas': () => {
            alert('Demonstração: Schemas\n\nSchemas organizam objetos do banco de dados.\n\nExemplos:\n• dbo (schema padrão)\n• Vendas\n• RH\n• Financeiro\n\nUso: Vendas.Produtos, RH.Funcionarios');
        }
    };
    
    if (demonstrations[concept]) {
        demonstrations[concept]();
    }
};

console.log('🚀 Sistema de aula SQL Server inicializado com sucesso!');
console.log('📚 Recursos disponíveis: Editor SQL, Exercícios Interativos, Visualizações 3D');
console.log('💡 Dica: Use as funções loadSampleQuery(), startExercise() e demonstrateConcept() para explorar o conteúdo!');