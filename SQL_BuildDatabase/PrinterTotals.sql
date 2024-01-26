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

