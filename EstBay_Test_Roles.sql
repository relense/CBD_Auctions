
use ESTBay

/* Criar utilizador com permissões de administrador para teste *//*
CREATE LOGIN test_admin_login WITH PASSWORD = 'test';
GO
CREATE USER test_admin_user FROM LOGIN test_admin_login
GO
ALTER ROLE administrador ADD MEMBER test_admin_user;
GO
*/

/* Criar utilizador com permissões de utilizador para teste *//*
CREATE LOGIN test_user_login WITH PASSWORD = 'test';
GO
CREATE USER test_user_user FROM LOGIN test_user_login
GO
ALTER ROLE utilizador ADD MEMBER test_user_user;
GO
*/


/* Criar utilizador com permissões de gestor financeiro para teste *//*
CREATE LOGIN test_gestor_login WITH PASSWORD = 'test';
GO
CREATE USER test_gestor_user FROM LOGIN test_gestor_login
GO
ALTER ROLE gestor_financeiro ADD MEMBER test_gestor_user;
GO
*/


EXECUTE AS LOGIN = N'test_user_login';
GO

/* Apenas o administrador consegue aceder */
--SELECT * FROM [v_display_readeble_auctions]

/* Apenas o administrador e o utilizador consegue aceder */
--SELECT * FROM [AUCTION.BIDS]
--EXEC usp_produtos_vendidos_com_melhor_classificacao

/* Apenas o administrador e o gestor financeiro consegue aceder*/
--SELECT * FROM [AUCTION.COMPRAS]


GO

REVERT