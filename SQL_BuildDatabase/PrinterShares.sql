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

