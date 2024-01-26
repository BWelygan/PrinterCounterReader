USE [PrintMon]
GO

/****** Object:  Table [dbo].[PrtFunctBridge]    Script Date: 2024-01-26 2:38:58 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[PrtFunctBridge](
	[prtSN] [nvarchar](50) NOT NULL,
	[fID] [uniqueidentifier] NOT NULL,
 CONSTRAINT [PK_PrtFunctBridge_prtSN_fID] PRIMARY KEY CLUSTERED 
(
	[prtSN] ASC,
	[fID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO

ALTER TABLE [dbo].[PrtFunctBridge]  WITH CHECK ADD  CONSTRAINT [FK_PrtFunctBridge_Printers] FOREIGN KEY([prtSN])
REFERENCES [dbo].[Printers] ([SN])
GO

ALTER TABLE [dbo].[PrtFunctBridge] CHECK CONSTRAINT [FK_PrtFunctBridge_Printers]
GO

ALTER TABLE [dbo].[PrtFunctBridge]  WITH CHECK ADD  CONSTRAINT [FK_PrtFunctBridge_fID] FOREIGN KEY([fID])
REFERENCES [dbo].[PrtFunction] ([fID])
GO

ALTER TABLE [dbo].[PrtFunctBridge] CHECK CONSTRAINT [FK_PrtFunctBridge_fID]
GO

