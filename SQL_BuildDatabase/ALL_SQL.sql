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

USE [PrintMon]
GO

/****** Object:  Table [dbo].[PrtShares]    Script Date: 2024-01-26 2:39:22 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[PrtShares](
	[shareID] [uniqueidentifier] NOT NULL,
	[prtSN] [nvarchar](50) NOT NULL,
	[ShareName] [nvarchar](40) NOT NULL,
	[HostingServer] [nvarchar](40) NOT NULL,
	[Decommissioned] [tinyint] NOT NULL,
 CONSTRAINT [PK_PrtShares_Share_Host] PRIMARY KEY NONCLUSTERED 
(
	[shareID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO

ALTER TABLE [dbo].[PrtShares] ADD  DEFAULT (newsequentialid()) FOR [shareID]
GO

ALTER TABLE [dbo].[PrtShares]  WITH CHECK ADD  CONSTRAINT [FK_PrtShares_prtSN] FOREIGN KEY([prtSN])
REFERENCES [dbo].[Printers] ([SN])
ON UPDATE CASCADE
ON DELETE CASCADE
GO

ALTER TABLE [dbo].[PrtShares] CHECK CONSTRAINT [FK_PrtShares_prtSN]
GO

USE [PrintMon]
GO

/****** Object:  Table [dbo].[PrtSupplies]    Script Date: 2024-01-26 2:39:44 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[PrtSupplies](
	[supplyID] [uniqueidentifier] NOT NULL,
	[sClass] [nvarchar](50) NOT NULL,
	[sDescription] [nvarchar](100) NOT NULL,
	[sUnit] [nvarchar](50) NOT NULL,
	[sMaxCapacity] [int] NOT NULL,
	[sType] [nvarchar](20) NULL,
	[sColourantValue] [nvarchar](255) NULL,
	[sPartNumber] [nvarchar](15) NULL,
 CONSTRAINT [PK_PrtSupplies_sID] PRIMARY KEY CLUSTERED 
(
	[supplyID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO

ALTER TABLE [dbo].[PrtSupplies] ADD  CONSTRAINT [DF_PrtSupplies_supplyID]  DEFAULT (newsequentialid()) FOR [supplyID]
GO

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

USE [PrintMon]
GO

/****** Object:  Table [dbo].[PrtTotals]    Script Date: 2024-01-26 2:40:24 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[PrtTotals](
	[prtTotalId] [uniqueidentifier] NOT NULL,
	[prtSN] [nvarchar](50) NOT NULL,
	[Total] [int] NULL,
	[TotalBW] [int] NULL,
	[TotalColour] [int] NULL,
	[total1] [int] NULL,
	[total2] [int] NULL,
	[totalLarge] [int] NULL,
	[totalSmall] [int] NULL,
	[totalBlack1] [int] NULL,
	[totalSingleColorLarge] [int] NULL,
	[totalSingleColorSmall] [int] NULL,
	[totalBlackLarge] [int] NULL,
	[totalBlackSmall] [int] NULL,
	[total1_2Sided] [int] NULL,
	[totalSingleColor1] [int] NULL,
	[totalFullColorSingleColorLarge] [int] NULL,
	[totalFullColorSingleColorSmall] [int] NULL,
	[totalA2] [int] NULL,
	[totalABlack2] [int] NULL,
	[totalAFullColorSingleColor2] [int] NULL,
	[copyTotal1] [int] NULL,
	[copyTotal2] [int] NULL,
	[copyLarge] [int] NULL,
	[copyBlack2] [int] NULL,
	[copyFullColorSingleColorLarge] [int] NULL,
	[copyFullColorSingleColorSmall] [int] NULL,
	[copyFullColorSingleColor2] [int] NULL,
	[copyFullColorSingleColor1] [int] NULL,
	[printTotal1] [int] NULL,
	[printFullColorSingleColorLarge] [int] NULL,
	[printFullColorSingleColorSmall] [int] NULL,
	[printFullColorSingleColor1] [int] NULL,
	[copyPrintFullColorLarge] [int] NULL,
	[copyPrintFullColorSmall] [int] NULL,
	[scanTotal1] [int] NULL,
	[receivePrintTotal1] [int] NULL,
	[receivePrintTotal2] [int] NULL,
	[receivePrintFullColorLarge] [int] NULL,
	[receivePrintFullColorSmall] [int] NULL,
	[receivePrintBlackLarge] [int] NULL,
	[receivePrintBlackSmall] [int] NULL,
	[receivePrintBlackLarge2Sided] [int] NULL,
	[receivePrintBlackSmall2Sided] [int] NULL,
	[Date] [datetime] NULL,
 CONSTRAINT [PK_PrintTotals] PRIMARY KEY CLUSTERED 
(
	[prtTotalId] ASC,
	[prtSN] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO

ALTER TABLE [dbo].[PrtTotals] ADD  CONSTRAINT [DF_CK_prtTotalId]  DEFAULT (newsequentialid()) FOR [prtTotalId]
GO

ALTER TABLE [dbo].[PrtTotals]  WITH CHECK ADD  CONSTRAINT [FK_PrintTotals_prtSN] FOREIGN KEY([prtSN])
REFERENCES [dbo].[Printers] ([SN])
GO

ALTER TABLE [dbo].[PrtTotals] CHECK CONSTRAINT [FK_PrintTotals_prtSN]
GO

