USE [PrintMon]
GO

/****** Object:  Table [dbo].[Printers]    Script Date: 2024-01-26 2:35:16 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[Printers](
	[SN] [nvarchar](50) NOT NULL,
	[SupportNumber] [nvarchar](50) NOT NULL,
	[Location] [nvarchar](50) NOT NULL,
	[Name] [nvarchar](50) NOT NULL,
	[IPAddress] [nvarchar](40) NOT NULL,
	[Model] [nvarchar](100) NOT NULL,
	[UpTime] [int] NOT NULL,
	[pOnline] [tinyint] NULL,
 CONSTRAINT [PK_Printers_SN] PRIMARY KEY NONCLUSTERED 
(
	[SN] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO

ALTER TABLE [dbo].[Printers] ADD  CONSTRAINT [DF_CK_pOnline]  DEFAULT ((0)) FOR [pOnline]
GO

