-- Schema para FreeRADIUS com PostgreSQL
-- Baseado no schema oficial do FreeRADIUS 3.x

-- Tabela de usuários (radcheck) - Credenciais de autenticação
CREATE TABLE IF NOT EXISTS radcheck (
    id SERIAL PRIMARY KEY,
    username VARCHAR(64) NOT NULL DEFAULT '',
    attribute VARCHAR(64) NOT NULL DEFAULT '',
    op CHAR(2) NOT NULL DEFAULT '==',
    value VARCHAR(253) NOT NULL DEFAULT '',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX radcheck_username_idx ON radcheck(username);

-- Tabela de respostas (radreply) - Atributos retornados após autenticação
CREATE TABLE IF NOT EXISTS radreply (
    id SERIAL PRIMARY KEY,
    username VARCHAR(64) NOT NULL DEFAULT '',
    attribute VARCHAR(64) NOT NULL DEFAULT '',
    op CHAR(2) NOT NULL DEFAULT '=',
    value VARCHAR(253) NOT NULL DEFAULT '',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX radreply_username_idx ON radreply(username);

-- Tabela de grupos (radgroupcheck) - Verificações de grupo
CREATE TABLE IF NOT EXISTS radgroupcheck (
    id SERIAL PRIMARY KEY,
    groupname VARCHAR(64) NOT NULL DEFAULT '',
    attribute VARCHAR(64) NOT NULL DEFAULT '',
    op CHAR(2) NOT NULL DEFAULT '==',
    value VARCHAR(253) NOT NULL DEFAULT ''
);
CREATE INDEX radgroupcheck_groupname_idx ON radgroupcheck(groupname);

-- Tabela de respostas de grupo (radgroupreply)
CREATE TABLE IF NOT EXISTS radgroupreply (
    id SERIAL PRIMARY KEY,
    groupname VARCHAR(64) NOT NULL DEFAULT '',
    attribute VARCHAR(64) NOT NULL DEFAULT '',
    op CHAR(2) NOT NULL DEFAULT '=',
    value VARCHAR(253) NOT NULL DEFAULT ''
);
CREATE INDEX radgroupreply_groupname_idx ON radgroupreply(groupname);

-- Tabela de associação usuário-grupo (radusergroup)
CREATE TABLE IF NOT EXISTS radusergroup (
    id SERIAL PRIMARY KEY,
    username VARCHAR(64) NOT NULL DEFAULT '',
    groupname VARCHAR(64) NOT NULL DEFAULT '',
    priority INT NOT NULL DEFAULT 1
);
CREATE INDEX radusergroup_username_idx ON radusergroup(username);

-- Tabela de accounting (radacct) - Logs de sessão
CREATE TABLE IF NOT EXISTS radacct (
    radacctid BIGSERIAL PRIMARY KEY,
    acctsessionid VARCHAR(64) NOT NULL,
    acctuniqueid VARCHAR(32) NOT NULL UNIQUE,
    username VARCHAR(64) DEFAULT NULL,
    realm VARCHAR(64) DEFAULT '',
    nasipaddress INET NOT NULL,
    nasportid VARCHAR(15) DEFAULT NULL,
    nasporttype VARCHAR(32) DEFAULT NULL,
    acctstarttime TIMESTAMP DEFAULT NULL,
    acctupdatetime TIMESTAMP DEFAULT NULL,
    acctstoptime TIMESTAMP DEFAULT NULL,
    acctinterval BIGINT DEFAULT NULL,
    acctsessiontime BIGINT DEFAULT NULL,
    acctauthentic VARCHAR(32) DEFAULT NULL,
    connectinfo_start VARCHAR(50) DEFAULT NULL,
    connectinfo_stop VARCHAR(50) DEFAULT NULL,
    acctinputoctets BIGINT DEFAULT NULL,
    acctoutputoctets BIGINT DEFAULT NULL,
    calledstationid VARCHAR(50) DEFAULT NULL,
    callingstationid VARCHAR(50) DEFAULT NULL,
    acctterminatecause VARCHAR(32) DEFAULT NULL,
    servicetype VARCHAR(32) DEFAULT NULL,
    framedprotocol VARCHAR(32) DEFAULT NULL,
    framedipaddress INET DEFAULT NULL
);
CREATE INDEX radacct_username_idx ON radacct(username);
CREATE INDEX radacct_nasipaddress_idx ON radacct(nasipaddress);
CREATE INDEX radacct_acctsessionid_idx ON radacct(acctsessionid);
CREATE INDEX radacct_acctstarttime_idx ON radacct(acctstarttime);
CREATE INDEX radacct_acctstoptime_idx ON radacct(acctstoptime);

-- Tabela de pós-autenticação (radpostauth) - Log de tentativas de autenticação
CREATE TABLE IF NOT EXISTS radpostauth (
    id BIGSERIAL PRIMARY KEY,
    username VARCHAR(64) NOT NULL,
    pass VARCHAR(64),
    reply VARCHAR(32),
    authdate TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    nasipaddress INET DEFAULT NULL,
    nasportid VARCHAR(15) DEFAULT NULL,
    packettype VARCHAR(64) DEFAULT NULL
);
CREATE INDEX radpostauth_username_idx ON radpostauth(username);
CREATE INDEX radpostauth_authdate_idx ON radpostauth(authdate);

-- Tabela customizada para gerenciar usuários da empresa
CREATE TABLE IF NOT EXISTS usuarios_empresa (
    id SERIAL PRIMARY KEY,
    username VARCHAR(64) UNIQUE NOT NULL,
    nome_completo VARCHAR(255) NOT NULL,
    email VARCHAR(255),
    departamento VARCHAR(100),
    ativo BOOLEAN DEFAULT TRUE,
    data_criacao TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    data_expiracao TIMESTAMP DEFAULT NULL,
    observacoes TEXT
);

-- Inserir usuários de exemplo
INSERT INTO usuarios_empresa (username, nome_completo, email, departamento) VALUES
('admin', 'Administrador do Sistema', 'admin@empresa.com', 'TI'),
('usuario.teste', 'Usuário Teste', 'teste@empresa.com', 'Operações');

-- Inserir credenciais de exemplo (senha: senha123)
-- Usando Cleartext-Password para teste (em produção use MD5 ou outro hash)
INSERT INTO radcheck (username, attribute, op, value) VALUES
('admin', 'Cleartext-Password', ':=', 'Admin@123'),
('usuario.teste', 'Cleartext-Password', ':=', 'senha123');

-- Criar grupos de exemplo
INSERT INTO radgroupcheck (groupname, attribute, op, value) VALUES
('administradores', 'Auth-Type', ':=', 'Accept'),
('usuarios_wifi', 'Auth-Type', ':=', 'Accept');

-- Atributos de resposta para grupos
INSERT INTO radgroupreply (groupname, attribute, op, value) VALUES
('administradores', 'Session-Timeout', ':=', '28800'),  -- 8 horas
('usuarios_wifi', 'Session-Timeout', ':=', '14400');     -- 4 horas

-- Associar usuários aos grupos
INSERT INTO radusergroup (username, groupname, priority) VALUES
('admin', 'administradores', 1),
('usuario.teste', 'usuarios_wifi', 1);

-- View para facilitar consultas
CREATE OR REPLACE VIEW v_usuarios_ativos AS
SELECT 
    u.username,
    u.nome_completo,
    u.email,
    u.departamento,
    u.ativo,
    r.value as senha,
    g.groupname as grupo
FROM usuarios_empresa u
LEFT JOIN radcheck r ON u.username = r.username AND r.attribute = 'Cleartext-Password'
LEFT JOIN radusergroup g ON u.username = g.username
WHERE u.ativo = TRUE;

COMMENT ON TABLE radcheck IS 'Armazena credenciais e atributos de verificação por usuário';
COMMENT ON TABLE radreply IS 'Armazena atributos de resposta por usuário';
COMMENT ON TABLE radacct IS 'Armazena logs de sessões (accounting)';
COMMENT ON TABLE radpostauth IS 'Armazena logs de tentativas de autenticação';
COMMENT ON TABLE usuarios_empresa IS 'Tabela customizada para gerenciar usuários da empresa';
