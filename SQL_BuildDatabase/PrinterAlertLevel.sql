USE [PrintMon]
GO

/****** Object:  Table [dbo].[PrtAlertLevel]    Script Date: 2024-01-26 2:38:43 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[PrtAlertLevel](
	[alID] [uniqueidentifier] NOT NULL,
	[alertLevel] [varchar](50) NULL,
 CONSTRAINT [PK_PrtAlertLevel_alID] PRIMARY KEY NONCLUSTERED 
(
	[alID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO

ALTER TABLE [dbo].[PrtAlertLevel] ADD  DEFAULT (newsequentialid()) FOR [alID]
GO

