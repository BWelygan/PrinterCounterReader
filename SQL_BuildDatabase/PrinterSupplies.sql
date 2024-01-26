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

