USE [PrintMon]
GO

/****** Object:  Table [dbo].[PrtAlertDesc]    Script Date: 2024-01-26 2:38:28 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[PrtAlertDesc](
	[adID] [uniqueidentifier] NOT NULL,
	[alertDescription] [varchar](100) NULL,
 CONSTRAINT [PK_PrtAlertDesc_adID] PRIMARY KEY NONCLUSTERED 
(
	[adID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO

ALTER TABLE [dbo].[PrtAlertDesc] ADD  DEFAULT (newsequentialid()) FOR [adID]
GO

