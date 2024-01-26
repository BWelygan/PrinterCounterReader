USE [PrintMon]
GO

/****** Object:  Table [dbo].[PrtSupplyBridge]    Script Date: 2024-01-26 2:39:59 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[PrtSupplyBridge](
	[suppliesID] [int] IDENTITY(1,1) NOT NULL,
	[supplyID] [uniqueidentifier] NOT NULL,
	[prtSN] [nvarchar](50) NOT NULL,
	[sInstallDate] [date] NULL,
	[sLevel] [int] NOT NULL,
	[sReplaceDate] [date] NULL,
	[sSerialNumber] [nvarchar](16) NULL,
	[sCartridgeType] [nvarchar](45) NULL,
	[sPageCountAtInstall] [int] NULL,
	[sSupplyStatus] [nvarchar](10) NULL,
	[sFirstKnownLevel] [int] NULL,
	[sUsage] [int] NULL,
	[sCalibrations] [int] NULL,
	[sCoverage] [int] NULL,
	[sDaysRemaining] [int] NULL,
 CONSTRAINT [PK_PrtSupplyBridge] PRIMARY KEY CLUSTERED 
(
	[suppliesID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY],
UNIQUE NONCLUSTERED 
(
	[suppliesID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO

ALTER TABLE [dbo].[PrtSupplyBridge]  WITH CHECK ADD  CONSTRAINT [FK_PrtSupplyBridge_prtSN] FOREIGN KEY([prtSN])
REFERENCES [dbo].[Printers] ([SN])
GO

ALTER TABLE [dbo].[PrtSupplyBridge] CHECK CONSTRAINT [FK_PrtSupplyBridge_prtSN]
GO

ALTER TABLE [dbo].[PrtSupplyBridge]  WITH CHECK ADD  CONSTRAINT [FK_PrtSupplyBridge_sID] FOREIGN KEY([supplyID])
REFERENCES [dbo].[PrtSupplies] ([supplyID])
GO

ALTER TABLE [dbo].[PrtSupplyBridge] CHECK CONSTRAINT [FK_PrtSupplyBridge_sID]
GO

