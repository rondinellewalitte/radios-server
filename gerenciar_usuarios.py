#!/usr/bin/env python3
"""
Script de Gerenciamento de Usuários RADIUS
Permite adicionar, remover, listar e gerenciar usuários do servidor RADIUS
"""

import sys
import psycopg2
from psycopg2.extras import RealDictCursor
from datetime import datetime
import getpass

# Configuração do banco de dados
DB_CONFIG = {
    'host': 'localhost',
    'port': 5432,
    'database': 'radius',
    'user': 'radius',
    'password': 'RadiusSecurePass123!'
}

class RadiusUserManager:
    def __init__(self):
        self.conn = None
        self.conectar()
    
    def conectar(self):
        """Conecta ao banco de dados PostgreSQL"""
        try:
            self.conn = psycopg2.connect(**DB_CONFIG)
            print("✓ Conectado ao banco de dados RADIUS")
        except Exception as e:
            print(f"✗ Erro ao conectar ao banco: {e}")
            sys.exit(1)
    
    def adicionar_usuario(self, username, senha, nome_completo, email, departamento, grupo='usuarios_wifi'):
        """Adiciona um novo usuário"""
        try:
            cursor = self.conn.cursor()
            
            # Inserir na tabela de usuários da empresa
            cursor.execute("""
                INSERT INTO usuarios_empresa (username, nome_completo, email, departamento)
                VALUES (%s, %s, %s, %s)
            """, (username, nome_completo, email, departamento))
            
            # Inserir credenciais
            cursor.execute("""
                INSERT INTO radcheck (username, attribute, op, value)
                VALUES (%s, 'Cleartext-Password', ':=', %s)
            """, (username, senha))
            
            # Associar ao grupo
            cursor.execute("""
                INSERT INTO radusergroup (username, groupname, priority)
                VALUES (%s, %s, 1)
            """, (username, grupo))
            
            self.conn.commit()
            print(f"✓ Usuário '{username}' adicionado com sucesso!")
            print(f"  Nome: {nome_completo}")
            print(f"  Email: {email}")
            print(f"  Departamento: {departamento}")
            print(f"  Grupo: {grupo}")
            
        except psycopg2.IntegrityError:
            self.conn.rollback()
            print(f"✗ Erro: Usuário '{username}' já existe!")
        except Exception as e:
            self.conn.rollback()
            print(f"✗ Erro ao adicionar usuário: {e}")
    
    def remover_usuario(self, username):
        """Remove um usuário"""
        try:
            cursor = self.conn.cursor()
            
            # Desativar ao invés de deletar (melhor para auditoria)
            cursor.execute("""
                UPDATE usuarios_empresa 
                SET ativo = FALSE 
                WHERE username = %s
            """, (username,))
            
            if cursor.rowcount == 0:
                print(f"✗ Usuário '{username}' não encontrado!")
                return
            
            self.conn.commit()
            print(f"✓ Usuário '{username}' desativado com sucesso!")
            
        except Exception as e:
            self.conn.rollback()
            print(f"✗ Erro ao remover usuário: {e}")
    
    def alterar_senha(self, username, nova_senha):
        """Altera a senha de um usuário"""
        try:
            cursor = self.conn.cursor()
            
            cursor.execute("""
                UPDATE radcheck 
                SET value = %s, updated_at = NOW()
                WHERE username = %s AND attribute = 'Cleartext-Password'
            """, (nova_senha, username))
            
            if cursor.rowcount == 0:
                print(f"✗ Usuário '{username}' não encontrado!")
                return
            
            self.conn.commit()
            print(f"✓ Senha do usuário '{username}' alterada com sucesso!")
            
        except Exception as e:
            self.conn.rollback()
            print(f"✗ Erro ao alterar senha: {e}")
    
    def listar_usuarios(self, apenas_ativos=True):
        """Lista todos os usuários"""
        try:
            cursor = self.conn.cursor(cursor_factory=RealDictCursor)
            
            query = "SELECT * FROM v_usuarios_ativos"
            if not apenas_ativos:
                query = """
                    SELECT u.username, u.nome_completo, u.email, u.departamento, 
                           u.ativo, g.groupname as grupo
                    FROM usuarios_empresa u
                    LEFT JOIN radusergroup g ON u.username = g.username
                """
            
            cursor.execute(query)
            usuarios = cursor.fetchall()
            
            if not usuarios:
                print("Nenhum usuário encontrado.")
                return
            
            print("\n" + "="*100)
            print(f"{'USERNAME':<20} {'NOME':<30} {'EMAIL':<30} {'DEPTO':<15} {'GRUPO':<15}")
            print("="*100)
            
            for user in usuarios:
                print(f"{user['username']:<20} {user['nome_completo']:<30} "
                      f"{user['email'] or 'N/A':<30} {user['departamento'] or 'N/A':<15} "
                      f"{user.get('grupo', 'N/A'):<15}")
            
            print("="*100)
            print(f"Total: {len(usuarios)} usuários")
            
        except Exception as e:
            print(f"✗ Erro ao listar usuários: {e}")
    
    def estatisticas(self):
        """Mostra estatísticas do servidor"""
        try:
            cursor = self.conn.cursor(cursor_factory=RealDictCursor)
            
            # Total de usuários ativos
            cursor.execute("SELECT COUNT(*) as total FROM usuarios_empresa WHERE ativo = TRUE")
            total_ativos = cursor.fetchone()['total']
            
            # Usuários por departamento
            cursor.execute("""
                SELECT departamento, COUNT(*) as total 
                FROM usuarios_empresa 
                WHERE ativo = TRUE 
                GROUP BY departamento 
                ORDER BY total DESC
            """)
            por_depto = cursor.fetchall()
            
            # Últimas autenticações
            cursor.execute("""
                SELECT username, authdate, reply, nasipaddress 
                FROM radpostauth 
                ORDER BY authdate DESC 
                LIMIT 10
            """)
            ultimas_auth = cursor.fetchall()
            
            # Sessões ativas
            cursor.execute("""
                SELECT COUNT(*) as total 
                FROM radacct 
                WHERE acctstoptime IS NULL
            """)
            sessoes_ativas = cursor.fetchone()['total']
            
            print("\n" + "="*80)
            print("ESTATÍSTICAS DO SERVIDOR RADIUS")
            print("="*80)
            print(f"\n📊 Total de usuários ativos: {total_ativos}")
            print(f"🔌 Sessões ativas: {sessoes_ativas}")
            
            print("\n📁 Usuários por departamento:")
            for depto in por_depto:
                print(f"  - {depto['departamento'] or 'Sem departamento'}: {depto['total']}")
            
            print("\n🔐 Últimas 10 autenticações:")
            for auth in ultimas_auth:
                status = "✓" if auth['reply'] == 'Access-Accept' else "✗"
                print(f"  {status} {auth['username']:<20} {auth['authdate']} "
                      f"from {auth['nasipaddress'] or 'N/A'}")
            
            print("="*80 + "\n")
            
        except Exception as e:
            print(f"✗ Erro ao buscar estatísticas: {e}")
    
    def fechar(self):
        """Fecha a conexão com o banco"""
        if self.conn:
            self.conn.close()
            print("✓ Conexão fechada")

def menu_principal():
    """Exibe o menu principal"""
    print("\n" + "="*60)
    print("GERENCIADOR DE USUÁRIOS RADIUS")
    print("="*60)
    print("1. Adicionar usuário")
    print("2. Remover (desativar) usuário")
    print("3. Alterar senha")
    print("4. Listar usuários")
    print("5. Estatísticas")
    print("0. Sair")
    print("="*60)
    return input("Escolha uma opção: ")

def main():
    manager = RadiusUserManager()
    
    while True:
        opcao = menu_principal()
        
        if opcao == '1':
            print("\n--- ADICIONAR USUÁRIO ---")
            username = input("Username: ")
            senha = getpass.getpass("Senha: ")
            nome_completo = input("Nome completo: ")
            email = input("Email: ")
            departamento = input("Departamento: ")
            grupo = input("Grupo [usuarios_wifi]: ") or "usuarios_wifi"
            
            manager.adicionar_usuario(username, senha, nome_completo, email, departamento, grupo)
        
        elif opcao == '2':
            print("\n--- REMOVER USUÁRIO ---")
            username = input("Username: ")
            confirma = input(f"Confirma desativação de '{username}'? (s/n): ")
            if confirma.lower() == 's':
                manager.remover_usuario(username)
        
        elif opcao == '3':
            print("\n--- ALTERAR SENHA ---")
            username = input("Username: ")
            nova_senha = getpass.getpass("Nova senha: ")
            manager.alterar_senha(username, nova_senha)
        
        elif opcao == '4':
            print("\n--- LISTAR USUÁRIOS ---")
            manager.listar_usuarios()
        
        elif opcao == '5':
            manager.estatisticas()
        
        elif opcao == '0':
            print("\nSaindo...")
            manager.fechar()
            break
        
        else:
            print("Opção inválida!")

if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        print("\n\nInterrompido pelo usuário.")
        sys.exit(0)
