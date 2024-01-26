USE [PrintMon]
GO

/****** Object:  Table [dbo].[PrtAlertBridge]    Script Date: 2024-01-26 2:38:07 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[PrtAlertBridge](
	[prtAlBrId] [int] IDENTITY(1,1) NOT NULL,
	[prtSN] [nvarchar](50) NOT NULL,
	[adID] [uniqueidentifier] NOT NULL,
	[alID] [uniqueidentifier] NOT NULL,
	[snmpTicks] [int] NULL,
	[alertDate] [smalldatetime] NOT NULL,
	[clearDate] [smalldatetime] NULL,
 CONSTRAINT [PK_PrtAlertBridge_prtAlBrId] PRIMARY KEY CLUSTERED 
(
	[prtAlBrId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY],
UNIQUE NONCLUSTERED 
(
	[prtAlBrId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO

ALTER TABLE [dbo].[PrtAlertBridge]  WITH CHECK ADD  CONSTRAINT [FK_PrtAlertBridge_adID] FOREIGN KEY([adID])
REFERENCES [dbo].[PrtAlertDesc] ([adID])
GO

ALTER TABLE [dbo].[PrtAlertBridge] CHECK CONSTRAINT [FK_PrtAlertBridge_adID]
GO

ALTER TABLE [dbo].[PrtAlertBridge]  WITH CHECK ADD  CONSTRAINT [FK_PrtAlertBridge_prtSN] FOREIGN KEY([prtSN])
REFERENCES [dbo].[Printers] ([SN])
GO

ALTER TABLE [dbo].[PrtAlertBridge] CHECK CONSTRAINT [FK_PrtAlertBridge_prtSN]
GO

ALTER TABLE [dbo].[PrtAlertBridge]  WITH CHECK ADD  CONSTRAINT [FK_PrtAlertLevel_alID] FOREIGN KEY([alID])
REFERENCES [dbo].[PrtAlertLevel] ([alID])
GO

ALTER TABLE [dbo].[PrtAlertBridge] CHECK CONSTRAINT [FK_PrtAlertLevel_alID]
GO

