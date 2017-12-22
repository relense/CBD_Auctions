USE master
GO

IF ( db_id('ESTBay_AG') IS NOT NULL )
DROP DATABASE ESTBay_AG
GO

CREATE DATABASE ESTBay_AG
GO

USE ESTBay_AG
GO

CREATE SCHEMA[USER]
GO

CREATE SCHEMA[AUCTION]
GO


CREATE TABLE [USER.USERS] (
IDUtilizador int IDENTITY(1,1),
Nome nVarChar(255) NOT NULL,
Email nVarChar(255) NOT NULL,
Pass VarBinary(128) NOT NULL,
DataDeNascimento Date NOT NULL,
PRIMARY KEY(IDUtilizador))
GO

CREATE TABLE[USER.PRODUCTS] (
IDProduto int IDENTITY(1,1),
IDVendedor int NOT NULL,
Nome nVarChar(255) NOT NULL,
Descricao nVarChar(255),
PRIMARY KEY(IDProduto),
FOREIGN KEY (IDVendedor)
	REFERENCES [USER.USERS]
)
GO

CREATE TABLE [USER.FOllOWS] (
Utilizador int,
UtilizadorSeguido int,
PRIMARY KEY (Utilizador, UtilizadorSeguido),
FOREIGN KEY(Utilizador)
	REFERENCES[USER.USERS],
FOREIGN KEY(UtilizadorSeguido)
	REFERENCES[USER.USERS]
)
GO

CREATE TABLE[USER.WATCHS] (
Utilizador int,
Produto int,
PRIMARY KEY(Utilizador, Produto),
FOREIGN KEY(Utilizador)
	REFERENCES[USER.USERS],
FOREIGN KEY(Produto)
	REFERENCES[USER.PRODUCTS]
		ON DELETE CASCADE
)
GO

CREATE TABLE[AUCTION.AUCTIONS] (
IDLeilao int IDENTITY(1,1),
Produto int,
Preco decimal(7,2) NOT NULL CHECK (Preco > 0),
DataDeLimiteLeilao smallDateTime NOT NULL,
DataDeCriacao smallDateTime NOT NULL,
Classificacao tinyint CHECK(Classificacao >= 0 AND Classificacao <= 5),
IDComprador int Default NULL,
PRIMARY KEY(IDLeilao),
FOREIGN KEY(Produto)
	REFERENCES[USER.PRODUCTS]
)
GO

CREATE TABLE[AUCTION.BIDS] (
IDLicitacao int IDENTITY(1,1),
IDLeilao int NOT NULL,
IDLicitador int NOT NULL,
Valor decimal(7,2) NOT NULL CHECK(Valor > 0),
DataLicitacao DateTime2 NOT NULL,
PRIMARY KEY(IDLicitacao),
FOREIGN KEY(IDLeilao)
	REFERENCES[AUCTION.AUCTIONS],
FOREIGN KEY(IDLicitador)
	REFERENCES[USER.USERS]
)
GO

CREATE TABLE[AUCTION.COMPRAS] (
IDFatura int IDENTITY(1,1),
NomeComprador nVarChar(255) NOT NULL,
NomeVendedor nVarChar(255) NOT NULL,
NomeProduto nVarChar(255) NOT NULL,
Valor Decimal(7,2) NOT NULL,
DataDeVenda Date NOT NULL
PRIMARY KEY(IDFatura)
)
GO

CREATE VIEW v_user_selling_product_count AS
SELECT [USER.USERS].IDUtilizador, COUNT(*) AS 'Número Productos à Venda'
FROM [USER.USERS]
INNER JOIN [USER.PRODUCTS] ON [USER.USERS].IDUtilizador = [USER.PRODUCTS].IDVendedor
INNER JOIN [AUCTION.AUCTIONS] ON [USER.PRODUCTS].IDProduto = [AUCTION.AUCTIONS].Produto
WHERE(DataDeLimiteLeilao > GETDATE())
GROUP BY [USER.USERS].IDUtilizador
GO

CREATE VIEW v_user_sold_product_count AS
SELECT [USER.USERS].IDUtilizador, COUNT(*) AS 'Número Productos Vendidos'
FROM [USER.USERS]
INNER JOIN [USER.PRODUCTS] ON [USER.USERS].IDUtilizador = [USER.PRODUCTS].IDVendedor
INNER JOIN [AUCTION.AUCTIONS] ON [USER.PRODUCTS].IDProduto = [AUCTION.AUCTIONS].Produto
WHERE(DataDeLimiteLeilao <= GETDATE() AND [AUCTION.AUCTIONS].IDComprador IS NOT NULL)
GROUP BY [USER.USERS].IDUtilizador
GO


CREATE VIEW v_user_bought_product_count AS
SELECT [USER.USERS].IDUtilizador, COUNT(*) AS 'Número Productos Comprados'
FROM [USER.USERS]
INNER JOIN [AUCTION.AUCTIONS] ON [USER.USERS].IDUtilizador = [AUCTION.AUCTIONS].IDComprador

WHERE (DataDeLimiteLeilao <= GETDATE() AND [AUCTION.AUCTIONS].IDComprador = [USER.USERS].IDUtilizador)
GROUP BY [USER.USERS].IDUtilizador
GO


CREATE VIEW v_user_product_average_classification AS
SELECT [USER.USERS].IDUtilizador, ROUND(AVG(CAST(Classificacao AS FLOAT)), 1) AS 'Média das Classificações'
FROM [USER.USERS]
INNER JOIN [USER.PRODUCTS] ON [USER.USERS].IDUtilizador = [USER.PRODUCTS].IDVendedor
INNER JOIN [AUCTION.AUCTIONS] ON [USER.PRODUCTS].IDProduto = [AUCTION.AUCTIONS].Produto
GROUP BY [USER.USERS].IDUtilizador
GO


CREATE VIEW v_product_maxbidder AS
SELECT [AUCTION.AUCTIONS].IDLeilao, MAX(Valor) as 'HighestBid'
FROM [AUCTION.AUCTIONS]
INNER JOIN [USER.PRODUCTS] ON [USER.PRODUCTS].IDProduto = [AUCTION.AUCTIONS].Produto
INNER JOIN [AUCTION.BIDS] ON [AUCTION.BIDS].IDLeilao = [AUCTION.AUCTIONS].IDLeilao
GROUP BY [AUCTION.AUCTIONS].IDLeilao
GO


CREATE VIEW v_display_product_and_seller_name AS
SELECT IDLeilao,
	[USER.PRODUCTS].Nome AS 'Produto',
	[USER.USERS].Nome AS 'Vendedor'
FROM [AUCTION.AUCTIONS]
INNER JOIN [USER.PRODUCTS] ON [USER.PRODUCTS].IDProduto = [AUCTION.AUCTIONS].Produto
INNER JOIN [USER.USERS] ON [USER.USERS].IDUtilizador = [USER.PRODUCTS].IDVendedor
GO

CREATE VIEW v_display_buyer_name AS
SELECT IDLeilao,
	[USER.USERS].Nome AS 'Comprador'
FROM [AUCTION.AUCTIONS]
INNER JOIN [USER.USERS] ON [USER.USERS].IDUtilizador = [AUCTION.AUCTIONS].IDComprador
GO



-- 2 fase VIEWS --

CREATE VIEW v_user_product_average_classification_ultimo_mes AS
SELECT [USER.USERS].IDUtilizador, ROUND(AVG(CAST(Classificacao AS FLOAT)), 1) AS 'Média das Classificações'
FROM [USER.USERS]
INNER JOIN [USER.PRODUCTS] ON [USER.USERS].IDUtilizador = [USER.PRODUCTS].IDVendedor
INNER JOIN [AUCTION.AUCTIONS] ON [USER.PRODUCTS].IDProduto = [AUCTION.AUCTIONS].Produto
WHERE (DATEPART(MONTH,DataDeLimiteLeilao) <= DATEADD(MONTH,-1,GETDATE()))
GROUP BY [USER.USERS].IDUtilizador

GO

-------------------


CREATE FUNCTION ufn_get_estado (@IDLeilao int)
RETURNS nVarChar(20)
AS
BEGIN
	DECLARE @DataLimite DateTime
	DECLARE @Comprador int
	DECLARE @Estado nVarChar(30)

	SELECT @Comprador = IDComprador, @DataLimite = DataDeLimiteLeilao
	FROM [AUCTION.AUCTIONS]
	WHERE IDLeilao = @IDLeilao

	IF (@DataLimite >= GETDATE())
		BEGIN
		IF (@Comprador IS NULL)
			SET @Estado = 'À Venda, sem Bid'
		ELSE
			SET @Estado = 'À Venda, com Bid'
		END
	ELSE
		BEGIN
		IF (@Comprador IS NULL)
			SET @Estado = 'Não Vendido'
		ELSE
			SET @Estado = 'Vendido'
		END
	RETURN @Estado
END
GO

CREATE VIEW v_display_readeble_auctions AS
SELECT [AUCTION.AUCTIONS].IDLeilao,
	Vendedor,
	v_display_product_and_seller_name.Produto,
	Comprador,
	dbo.ufn_get_estado([AUCTION.AUCTIONS].IDLeilao) AS 'Estado',
	Preco,
	Classificacao
	
FROM [AUCTION.AUCTIONS]
LEFT JOIN v_display_buyer_name ON v_display_buyer_name.IDLeilao = [AUCTION.AUCTIONS].IDLeilao
INNER JOIN v_display_product_and_seller_name ON v_display_product_and_seller_name.IDLeilao = [AUCTION.AUCTIONS].IDLeilao
GO


CREATE FUNCTION ufn_get_age_years (@dob  datetime)
RETURNS int -- Years
AS
BEGIN
	RETURN (DATEDIFF(hour,@dob,GETDATE())/8766)
END
GO


CREATE FUNCTION ufn_encrypt_password (@pw VarChar(128))
RETURNS VarBinary(128) -- Hash da password em texto
AS
BEGIN
	RETURN (PWDENCRYPT (@pw))
END
GO

CREATE FUNCTION ufn_compare_password (@user int, @pw VarChar(128))
RETURNS bit -- Password correta (1) ou não (0)
AS
BEGIN
	return (PWDCOMPARE(@pw, (SELECT Pass FROM [USER.USERS] WHERE IDUtilizador = @user)))
END
GO

CREATE FUNCTION ufn_email_exists (@Email nVarChar(255))
RETURNS bit -- Password correta (1) ou não (0)
AS
BEGIN	
	IF ((SELECT COUNT(*) FROM [USER.USERS] WHERE Email = @Email) > 0)
	return 1
	return 0
END
GO



CREATE PROCEDURE usp_register_user 
	@Nome nVarChar(255),
	@Email nVarChar(255),
	@Pass nVarChar(128),
	@DataNascimento Date
AS
BEGIN
	DECLARE @PassEncrypted VarBinary(128)

	IF @Nome IS NULL
		BEGIN
		RAISERROR('Nome em Branco!',16,1)
		RETURN
		END

	IF @Pass IS NULL
		BEGIN
		RAISERROR('Pass em Branco!',16,1)
		RETURN
		END

	IF @DataNascimento IS NULL
		BEGIN
		RAISERROR('Data de Nascimento em Branco!',16,1)
		RETURN
		END

	IF @Email NOT LIKE '%_@__%.__%'
		BEGIN
		RAISERROR('Formatacao do email errada, tem de ser do tipo: exemplo@email.com!',16,1)
		RETURN
		END
		
	IF (dbo.ufn_email_exists(@Email)) = 1
		BEGIN
		RAISERROR('Email já existente!',16,1)
		RETURN
		END

	EXEC @PassEncrypted = dbo.ufn_encrypt_password @Pass

	INSERT INTO [USER.USERS] (Nome, Email, Pass, DataDeNascimento)
		VALUES(@Nome, @Email, @PassEncrypted, @DataNascimento);
END
GO


CREATE PROCEDURE usp_auction_product
	@Vendedor int,
	@Nome nVarChar(255),
	@Descricao nVarChar(255),
	@DataLimite smalLDateTime,
	@Preco VarChar(7)

AS
BEGIN
	DECLARE @IDProducto numeric(38,0)

	IF @Vendedor IS NULL
		BEGIN
		RAISERROR('Vendedor em Branco!',16,1)
		RETURN
		END

	IF @Nome IS NULL
		BEGIN
		RAISERROR('Nome do Producto em Branco!',16,1)
		RETURN
		END
		
	IF @DataLimite IS NULL
		BEGIN
		RAISERROR('Data Limite em Branco!',16,1)
		RETURN
		END
		
	IF @Preco IS NULL
		BEGIN
		RAISERROR('Valor Minimo em Branco!',16,1)
		RETURN
		END

	IF ISNUMERIC(@Preco + '.0e0') = 0
		BEGIN
		RAISERROR('Valor tem de ser um inteiro!',16,1)
		RETURN
		END


	INSERT INTO [USER.PRODUCTS] (IDVendedor, Nome, Descricao)
		VALUES(@Vendedor, @Nome, @Descricao);

	SET @IDProducto = SCOPE_IDENTITY()

	INSERT INTO [AUCTION.AUCTIONS] (Produto, DataDeLimiteLeilao, DataDeCriacao, Preco)
		VALUES(@IDProducto, @DataLimite, GETDATE(), @Preco);
END
GO



CREATE PROCEDURE usp_licitar
	@IDLeilao int,
	@IDLicitador nVarChar(255),
	@Valor varChar(7)

AS
BEGIN

	IF @IDLeilao IS NULL
		BEGIN
		RAISERROR('Leilão em Branco!',16,1)
		RETURN
		END

	IF @IDLicitador IS NULL
		BEGIN
		RAISERROR('Licitador em Branco!',16,1)
		RETURN
		END
		
	IF @Valor IS NULL
		BEGIN
		RAISERROR('Valor em Branco!',16,1)
		RETURN
		END

	IF ISNUMERIC(@Valor + '.0e0') = 0
		BEGIN
		RAISERROR('Valor tem de ser um inteiro!',16,1)
		RETURN
		END
		
	DECLARE @PrecoAtual decimal(7,2)
	DECLARE @DataLimite smallDateTime
	DECLARE @IDComprador int
	DECLARE @IDProduto int
	DECLARE @IDVendedor int
	DECLARE @HighestBid decimal(7,2)
	
	SELECT @PrecoAtual = Preco, @DataLimite = DataDeLimiteLeilao, @IDComprador = IDComprador, @IDProduto = Produto
	FROM [AUCTION.AUCTIONS]
	WHERE IDLeilao = @IDLeilao

	SELECT @IDVendedor = IDVendedor
	FROM [USER.PRODUCTS]
	WHERE IDProduto = @IDProduto

	SELECT @HighestBid = HighestBid
	FROM [v_product_maxbidder]
	WHERE IDLeilao = @IDLeilao

	IF (@IDVendedor = @IDLicitador)
		BEGIN
		RAISERROR('O vendedor não pode licitar nos seus produto!',16,1)
		RETURN
		END

	IF (@DataLimite <= GETDATE())
		BEGIN
		RAISERROR('Leilão já terminou!',16,1)
		RETURN
		END

	IF (@Valor <= @PrecoAtual)
		BEGIN
		RAISERROR('Valor menor ou igual ao preco atual!',16,1)
		RETURN
		END
		
	DECLARE @NovoPreco decimal(7,2)
	DECLARE @NovoComprador int

	IF (@Valor > @PrecoAtual AND @HighestBid IS NULL)
	BEGIN
		SET @NovoPreco = (@PrecoAtual + 1)
		SET @NovoComprador = @IDLicitador
	END

	ELSE IF (@Valor > @HighestBid)
	BEGIN
		SET @NovoPreco = (@HighestBid + 1)
		SET @NovoComprador = @IDLicitador
	END

	ELSE IF (@Valor < @HighestBid)
	BEGIN
		SET @NovoPreco = (@Valor + 1)
		SET @NovoComprador = @IDComprador
	END

	ELSE IF (@Valor = @HighestBid)
	BEGIN
		SET @NovoPreco = @HighestBid
		SET @NovoComprador = @IDComprador
	END

	INSERT INTO [AUCTION.BIDS] (IDLeilao, IDLicitador, Valor, DataLicitacao)
		VALUES(@IDLeilao, @IDLicitador, @Valor, GETDATE());

	UPDATE [AUCTION.AUCTIONS]
	SET Preco = @NovoPreco, IDComprador = @NovoComprador
	WHERE IDLeilao = @IDLeilao

END
GO

--2Fase STORE PROCEDURES--

CREATE PROCEDURE usp_modificar_password
	@PWAntiga VarChar(128),
	@PWNova VarChar(128),
	@user int

AS
BEGIN

	DECLARE @PassEncrypted VarBinary(128)

	IF dbo.ufn_compare_password(@user, @PWAntiga) = 0
		BEGIN
		RAISERROR('Password atual não corresponde!',16,1)
		RETURN
		END

	ELSE
		BEGIN
		SELECT @PassEncrypted = dbo.ufn_encrypt_password (@PWNova)
		END

	UPDATE [USER.USERS]
	SET Pass = @PassEncrypted
	WHERE IDUtilizador = @user;

END
GO


CREATE PROCEDURE usp_produtos_seguidos_por_utilizador
	@user int
	OUTPUT
AS
BEGIN
	SELECT [USER.WATCHS].Produto
	FROM [USER.WATCHS]
	WHERE(Utilizador = @user)
END
GO

CREATE PROCEDURE usp_produtos_a_venda_por_utilizador
	@user int
	OUTPUT
AS
BEGIN
	SELECT [USER.PRODUCTS].IDProduto, [USER.PRODUCTS].Nome
	FROM [USER.PRODUCTS]
	INNER JOIN [AUCTION.AUCTIONS] ON [USER.PRODUCTS].IDProduto = [AUCTION.AUCTIONS].Produto
	WHERE(IDVendedor = @user AND DataDeLimiteLeilao > GETDATE())
END
GO



CREATE PROCEDURE usp_licitacoes_ativas_do_utilizador
	@user int
	OUTPUT
AS
BEGIN
	SELECT [AUCTION.BIDS].IDLicitacao, [AUCTION.AUCTIONS].Produto, [USER.PRODUCTS].Nome, [AUCTION.BIDS].Valor
	FROM [AUCTION.BIDS]
	INNER JOIN [AUCTION.AUCTIONS] ON [AUCTION.BIDS].IDLeilao = [AUCTION.AUCTIONS].IDLeilao
	INNER JOIN [USER.PRODUCTS] ON [USER.PRODUCTS].IDProduto = [AUCTION.AUCTIONS].Produto
	WHERE([AUCTION.BIDS].IDLicitador = @user AND DataDeLimiteLeilao > GETDATE())
END
GO


CREATE PROCEDURE usp_mostrar_produtos_vendidos_por_utilizador
	@user int
	OUTPUT
AS
BEGIN
	SELECT [USER.PRODUCTS].IDProduto, [USER.PRODUCTS].Nome
	FROM [USER.PRODUCTS]
	INNER JOIN [AUCTION.AUCTIONS] ON [USER.PRODUCTS].IDProduto = [AUCTION.AUCTIONS].Produto
	WHERE([USER.PRODUCTS].IDVendedor = @user AND DataDeLimiteLeilao <= GETDATE() AND [AUCTION.AUCTIONS].IDComprador IS NOT NULL)
END
GO


CREATE PROCEDURE usp_compras_sem_classificacao
	@user int
	OUTPUT
AS
BEGIN
	SELECT [AUCTION.AUCTIONS].IDLeilao, [USER.PRODUCTS].IDProduto, [USER.PRODUCTS].Nome
	FROM [AUCTION.AUCTIONS]
	INNER JOIN [USER.PRODUCTS] ON [USER.PRODUCTS].IDProduto = [AUCTION.AUCTIONS].Produto
	WHERE(DataDeLimiteLeilao <= GETDATE() AND [AUCTION.AUCTIONS].IDComprador = @user AND [AUCTION.AUCTIONS].Classificacao IS NULL)
END
GO


CREATE PROCEDURE usp_classificar_compra_user
	@auction int,
	@classificacao tinyint
AS
BEGIN
	UPDATE [AUCTION.AUCTIONS]
	SET Classificacao=@classificacao
	WHERE(DataDeLimiteLeilao <= GETDATE() AND [AUCTION.AUCTIONS].IDComprador IS NOT NULL AND [AUCTION.AUCTIONS].Classificacao IS NULL)
END
GO



CREATE PROCEDURE usp_produtos_vendidos_com_melhor_classificacao
AS
BEGIN
	SELECT v_user_product_average_classification.IDUtilizador, v_user_product_average_classification.[Média das Classificações]
	FROM v_user_product_average_classification
	INNER JOIN [USER.USERS] ON v_user_product_average_classification.IDUtilizador = [USER.USERS].IDUtilizador 
	ORDER BY v_user_product_average_classification.[Média das Classificações] DESC, [USER.USERS].Nome
END
GO

CREATE PROCEDURE usp_produtos_vendidos_com_melhor_classificacao_mes
AS
BEGIN
	SELECT v_user_product_average_classification_ultimo_mes.IDUtilizador, v_user_product_average_classification_ultimo_mes.[Média das Classificações] 
	FROM v_user_product_average_classification_ultimo_mes
	INNER JOIN [USER.USERS] ON v_user_product_average_classification_ultimo_mes.IDUtilizador = [USER.USERS].IDUtilizador 
	ORDER BY v_user_product_average_classification_ultimo_mes.[Média das Classificações] DESC, [USER.USERS].Nome
	
END
GO



CREATE PROCEDURE usp_export_finished_auctions_to_compras
AS
BEGIN
	
	INSERT INTO [AUCTION.COMPRAS] (NomeComprador, NomeVendedor, NomeProduto, Valor, DataDeVenda)
		SELECT v_display_buyer_name.Comprador, v_display_product_and_seller_name.Vendedor, v_display_product_and_seller_name.Produto, [AUCTION.AUCTIONS].Preco, [AUCTION.AUCTIONS].DataDeLimiteLeilao
		FROM [AUCTION.AUCTIONS]
		INNER JOIN v_display_buyer_name ON v_display_buyer_name.IDLeilao = [AUCTION.AUCTIONS].IDLeilao
		INNER JOIN v_display_product_and_seller_name ON v_display_product_and_seller_name.IDLeilao = [AUCTION.AUCTIONS].IDLeilao
		WHERE (DataDeLimiteLeilao <= GETDATE() AND [AUCTION.AUCTIONS].IDComprador IS NOT NULL)
END
GO


CREATE TRIGGER t_cascade_delete_user
ON [USER.USERS]
AFTER DELETE
AS
DECLARE @IDUtilizador int

SELECT @IDUtilizador = IDUtilizador
FROM deleted;

DELETE FROM [USER.FOllOWS]
WHERE Utilizador = @IDUtilizador OR UtilizadorSeguido = @IDUtilizador
GO

/*
EXEC usp_register_user 'Xines Lalanja', 'Xines@lalanja.cn', '1234', '2001-03-21'
EXEC usp_register_user 'Vaca Galo Arroz', 'Vaca@Galo.Arroz', 'Batata', '1993-06-13'
EXEC usp_register_user 'Pink Guy', 'ey_bauss@filthyfrank.com', 'Banana', '1991-12-3'
EXEC usp_register_user '3PO', '3po@sw.com', 'ana', '1990-3-27'
EXEC usp_register_user 'R2-D2', 'r2d2@sw.com', 'kin', '1950-9-4'
EXEC usp_register_user 'Miguel Furtado', 'miguel.furtado@gmail.com', 'booty', '1991-12-3'
EXEC usp_register_user 'Le Dracula', 'bite@meplox.com', 'dentinho', '1645-01-01'
EXEC usp_register_user 'Saitama', 'one@punch.man', 'dead', '1989-03-23'
EXEC usp_register_user 'Genos', 'genos@cyborg.com', 'saitamasempai', '1988-5-19'
EXEC usp_register_user 'Lee Sin', 'to@your.heart', 'HUA', '1986-3-27'

EXEC usp_auction_product 1, 'Batatas', 'Tuberculo bom para encher o bandulho', '2015-12-30', 3
EXEC usp_auction_product 2, 'Banana', 'Fruta tropical possui uma polpa macia, saborosa e doce', '2015-12-27', 4
EXEC usp_auction_product 3, 'Lalanja', 'CÔDELALANJAAAAAAAAAAAAAAAAAAAAAAA', '2015-12-21', 5
EXEC usp_auction_product 4, 'Barco', '20 Metros, com 5 anos, gasolina, 2 motores', '2016-2-6', 27000
EXEC usp_auction_product 5, 'Gameboy', 'Amalelo, um "bocado" riscado *wink wink*', '2016-7-30', 5
EXEC usp_auction_product 6, 'Arduino Uno R3', '5V Original, 16Mhz fabricado em Itália', '2016-12-4', 29
EXEC usp_auction_product 7, 'Raspberry Pi Zero', '5V 180mA 1 usb, mini hdmi, 1Ghz 512Mb Ram', '2016-6-15', 5
EXEC usp_auction_product 8, 'Oculos Raybom', 'Muito swagg 4real', '2016-9-24', 10
EXEC usp_auction_product 9, 'Moet Chandomix', 'Imitação barata mas muito realista', '2016-4-1', 3
EXEC usp_auction_product 10, 'Lazer verde', 'Chega até à lua, *blinded*', '2016-5-25', 200

/* ID Leilão, ID Licitador, Preço da Bid */
EXEC usp_licitar 1, 2, 4
EXEC usp_licitar 1, 3, 7
EXEC usp_licitar 1, 4, 6
EXEC usp_licitar 2, 1, 5
EXEC usp_licitar 2, 3, 8
EXEC usp_licitar 3, 4, 7
EXEC usp_licitar 3, 5, 11
EXEC usp_licitar 3, 6, 10
EXEC usp_licitar 4, 5, 27001
EXEC usp_licitar 4, 6, 27500
EXEC usp_licitar 4, 7, 30000
EXEC usp_licitar 4, 8, 28000
EXEC usp_licitar 6, 7, 30
EXEC usp_licitar 6, 8, 35
EXEC usp_licitar 6, 9, 33
EXEC usp_licitar 7, 8, 6
EXEC usp_licitar 7, 9, 7
EXEC usp_licitar 8, 9, 11
EXEC usp_licitar 8, 10, 20
EXEC usp_licitar 8, 9, 20
EXEC usp_licitar 8, 1, 21
EXEC usp_licitar 9, 10, 4
EXEC usp_licitar 9, 1, 5
EXEC usp_licitar 9, 2, 9
EXEC usp_licitar 9, 3, 7
EXEC usp_licitar 10, 1, 201
EXEC usp_licitar 10, 2, 254
EXEC usp_licitar 10, 3, 512
EXEC usp_licitar 10, 1, 1024
*/

--SELECT * FROM [AUCTION.AUCTIONS]

--SELECT * FROM [v_user_selling_product_count]
--SELECT * FROM [v_user_sold_product_count]
--SELECT * FROM [v_user_bought_product_count]
--SELECT * FROM [v_user_product_average_classification]
--SELECT * FROM [v_product_maxbidder]
--SELECT * FROM [v_display_readeble_auctions] /* Mostra os leilões com informação legível */


--Teste Função ufn_get_age_years devolve a idade em anos entre a data dada e a data atual
--SELECT IDUtilizador, Nome, dbo.ufn_get_age_years([USER.USERS].DataDeNascimento) AS 'Idade'
--FROM [USER.USERS]

--Teste Função ufn_compare_password e da dbo.ufn_encrypt_password
--SELECT IDUtilizador, dbo.ufn_compare_password( [USER.USERS].IDUtilizador, 'ABCd') AS 'Matched'
--FROM [USER.USERS]


INSERT INTO [AUCTION.COMPRAS]
VALUES ('a', 'replicacao', 'já_funca!!!', 5.80, GETDATE())
INSERT INTO [AUCTION.COMPRAS]
VALUES ('A', 'Replicacao', 'já_funca', 6.80, GETDATE())
INSERT INTO [AUCTION.COMPRAS]
VALUES ('a', 'triplicacao', 'Funca!!!', 7.80, GETDATE())
GO


INSERT INTO [USER.USERS]
  VALUES('XINES11LALANJA', 'XINES@LALANJA.11', dbo.ufn_encrypt_password ('ABCD'), '2001-03-21');
INSERT INTO [USER.USERS]
  VALUES('RAJVNIR', 'RAJVNIR@RAJVNIR.33', dbo.ufn_encrypt_password ('12345'), '1998-03-21');
INSERT INTO [USER.USERS]
  VALUES('LILITH', 'LITH@POX.33', dbo.ufn_encrypt_password ('123456'), '1989-03-21');

INSERT INTO [USER.PRODUCTS]
  VALUES(1, 'lalanja', 'poopi0');
INSERT INTO [USER.PRODUCTS]
  VALUES(1, 'lalanja1', 'poopi1');
INSERT INTO [USER.PRODUCTS]
  VALUES(1, 'lalanja2', 'poopi2');

INSERT INTO [AUCTION.AUCTIONS]
  VALUES(1, 10, '2015-11-30', GETDATE(), 5, 2);
INSERT INTO [AUCTION.AUCTIONS]
  VALUES(2, 10, '2015-11-30', GETDATE(), 5, NULL);
INSERT INTO [AUCTION.AUCTIONS]
  VALUES(3, 15, '2015-11-30', GETDATE(), 4, 3);
  
INSERT INTO [AUCTION.BIDS]
  VALUES(1, 2, 10.5, GETDATE());
INSERT INTO [AUCTION.BIDS]
  VALUES(1, 3, 12, GETDATE());
INSERT INTO [AUCTION.BIDS]
  VALUES(1, 2, 18, GETDATE());
INSERT INTO [AUCTION.BIDS]
  VALUES(1, 3, 150, GETDATE());
INSERT INTO [AUCTION.BIDS]
  VALUES(1, 2, 360, GETDATE());
INSERT INTO [AUCTION.BIDS]
  VALUES(3, 3, 14.3, GETDATE());
GO


-- ROLES --

CREATE ROLE administrador
GRANT CONTROL ON DATABASE::ESTBay_AG TO administrador


CREATE ROLE gestor_financeiro AUTHORIZATION administrador
GRANT SELECT ON OBJECT::[AUCTION.COMPRAS] TO gestor_financeiro;


CREATE ROLE utilizador AUTHORIZATION administrador
GRANT SELECT ON OBJECT::[AUCTION.BIDS] TO utilizador;
GRANT SELECT ON OBJECT::[AUCTION.AUCTIONS] TO utilizador;

GRANT EXECUTE ON OBJECT::dbo.usp_register_user TO utilizador;
GRANT EXECUTE ON OBJECT::dbo.usp_auction_product TO utilizador;
GRANT EXECUTE ON OBJECT::dbo.usp_licitar TO utilizador;
GRANT EXECUTE ON OBJECT::dbo.usp_modificar_password TO utilizador;
GRANT EXECUTE ON OBJECT::dbo.usp_produtos_seguidos_por_utilizador TO utilizador;
GRANT EXECUTE ON OBJECT::dbo.usp_produtos_a_venda_por_utilizador TO utilizador;
GRANT EXECUTE ON OBJECT::dbo.usp_licitacoes_ativas_do_utilizador TO utilizador;
GRANT EXECUTE ON OBJECT::dbo.usp_mostrar_produtos_vendidos_por_utilizador TO utilizador;
GRANT EXECUTE ON OBJECT::dbo.usp_compras_sem_classificacao TO utilizador;
GRANT EXECUTE ON OBJECT::dbo.usp_classificar_compra_user TO utilizador;
GRANT EXECUTE ON OBJECT::dbo.usp_produtos_vendidos_com_melhor_classificacao TO utilizador;
GRANT EXECUTE ON OBJECT::dbo.usp_produtos_vendidos_com_melhor_classificacao_mes TO utilizador;


GO 
