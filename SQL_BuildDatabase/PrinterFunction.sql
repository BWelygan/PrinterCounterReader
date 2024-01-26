USE [PrintMon]
GO

/****** Object:  Table [dbo].[PrtFunction]    Script Date: 2024-01-26 2:39:10 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[PrtFunction](
	[fID] [uniqueidentifier] NOT NULL,
	[prtFunction] [varchar](100) NOT NULL,
 CONSTRAINT [PK_PrtFunction_fID] PRIMARY KEY NONCLUSTERED 
(
	[fID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO

ALTER TABLE [dbo].[PrtFunction] ADD  CONSTRAINT [DF_CK_fID]  DEFAULT (newsequentialid()) FOR [fID]
GO

