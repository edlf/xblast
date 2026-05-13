#ifndef _BootFATX_H_
#define _BootFATX_H_

// Definitions for FATX on-disk structures
// (c) 2001 Andrew de Quincey

#include <stdbool.h>
#include <stdint.h>

#define STORE_SIZE       (0x131F00000ULL)
#define SYSTEM_SIZE      (0x1f400000UL)
#define CACHE1_SIZE      (0x2ee80000UL)
#define CACHE2_SIZE      (0x2ee80000UL)
#define CACHE3_SIZE      (0x2ee80000UL)

#define SECTOR_EXTEND    (0x00EE8AB0UL)
#define SECTOR_STORE     (0x0055F400UL)
#define SECTOR_SYSTEM    (0x00465400UL)
#define SECTOR_CONFIG    (0x00000000UL)
#define SECTOR_CACHE1    (0x00000400UL)
#define SECTOR_CACHE2    (0x00177400UL)
#define SECTOR_CACHE3    (0x002EE400UL)

#define SECTORD_CONFIG	 (SECTOR_CACHE1 - SECTOR_CONFIG)
#define SECTORS_STORE    (SECTOR_EXTEND - SECTOR_STORE)         //0x9896B0
#define SECTORS_SYSTEM   (SECTOR_STORE  - SECTOR_SYSTEM)
#define SECTORS_CACHE1   (SECTOR_CACHE2 - SECTOR_CACHE1)
#define SECTORS_CACHE2   (SECTOR_CACHE3 - SECTOR_CACHE2)
#define SECTORS_CACHE3   (SECTOR_SYSTEM - SECTOR_CACHE3)


#define XboxPartitionTableEntryCount 14

#define XBOX_PART_F_LBA_START (0xabe80000 + STORE_SIZE)

#define LBA48_Partition_Table_Magic_Size  0x10
#define LBA48_Partition_Table_Magic "****PARTINFO****"
#define LBA48_Partition_Name_C      "XBOX SHELL C"
#define LBA48_Partition_Name_E      "XBOX DATA E"
#define LBA48_Partition_Name_X      "XBOX CACHE X"
#define LBA48_Partition_Name_Y      "XBOX CACHE Y"
#define LBA48_Partition_Name_Z      "XBOX CACHE Z"
#define LBA48_Partition_Name_F      "XBOX EXTRA F"
#define LBA48_Partition_Name_G      "XBOX EXTRA G"

#define LBASIZE_137GB   (0x0FFFFFFFUL - SECTOR_EXTEND)    // LBA28 limited F: drive size.

#define FATX16_MAXLBA   2096800UL                         // Max number of sectors possible of a FATX16 partition. Higher than that is FATX32.

#define LBA_MAX_SIZE     0x0000FFFFFFFFFFFF
#define LBA_HIGHER_BITS  0x0000FFFF
#define LBA_LOWER_BITS   0xFFFFFFFF

/*Taken from XBPartitionner*/
// This flag (part of PARTITION_ENTRY.pe_flags) tells you whether/not a
// partition is being used (whether/not drive G is active, for example)
#define PE_PARTFLAGS_IN_USE 0x80000000


// Size of FATX partition header (boot sector/superblock)
#define FATX_PARTITION_HEADERSIZE 0x1000

// FATX partition magic
#define FATX_PARTITION_MAGIC 0x58544146         //"FATX" in ASCII.

// FATX chain table block size
#define FATX_CHAINTABLE_BLOCKSIZE 4096

// ID of the root FAT cluster
#define FATX_ROOT_FAT_CLUSTER 1

// Size of FATX directory entries
#define FATX_DIRECTORYENTRY_SIZE 0x40

// File attribute: read only
#define FATX_FILEATTR_READONLY 0x01

// File attribute: hidden
#define FATX_FILEATTR_HIDDEN 0x02

// File attribute: system
#define FATX_FILEATTR_SYSTEM 0x04

// File attribute: archive
#define FATX_FILEATTR_ARCHIVE 0x20

// Directory entry flag indicating entry is a sub-directory
#define FATX_FILEATTR_DIRECTORY 0x10

// max filename size
#define FATX_FILENAME_MAX 42

//Default number of retry if Write to disc fails.
#define DEFAULT_WRITE_RETRY     3

#define FATX16CLUSTERSIZE 16384

#define FATX_MAX_FILES_FOLDER 4096

// This structure describes a FATX partition
typedef struct {
  int nDriveIndex;

  // The starting byte of the partition
  uint64_t partitionStart;

  // The size of the partition in bytes
  uint64_t partitionSize;

  // The cluster size of the partition
  uint32_t clusterSize;

  // Number of clusters in the partition
  uint32_t clusterCount;

  // Size of entries in the cluster chain map
  uint32_t chainMapEntrySize;

  // The cluster chain map table (which may be in words OR dwords)
  union {
    uint16_t *words;
    uint32_t *dwords;
  } clusterChainMap;

  // Address of cluster 1
  uint64_t cluster1Address;

} FATXPartition;

typedef struct {                                        //Also known as FATX SuperBlock.
    uint32_t magic;
    uint32_t volumeID;
    uint32_t clusterSize;
    uint16_t nbFAT;
    uint32_t unknown;
    unsigned char  unused[0xfee];
}__attribute__((packed)) PARTITIONHEADER;               //For a total of 4096(0x1000) bytes.

typedef struct {
    char filename[FATX_FILENAME_MAX];
    int clusterId;
    uint32_t fileSize;
    uint32_t fileRead;
    unsigned char *buffer;
} FATXFILEINFO;

//Taken from ReactOS' vfat.h source and Xbox-Linux archives.
typedef struct {
    unsigned char FilenameLength;
    unsigned char Attrib;
    char Filename[42];
    uint32_t FirstCluster;
    uint32_t FileSize;
    uint16_t UpdateTime;
    uint16_t UpdateDate;
    uint16_t CreationTime;
    uint16_t CreationDate;
    uint16_t AccessTime;
    uint16_t AccessDate;
}__attribute__((packed)) FATXDIRINFO;                   //For a total of 64 bytes.

typedef struct
{
    unsigned char Name[16];
    uint32_t Flags;
    uint32_t LBAStart;
    uint32_t LBASize;
    uint16_t LBAStart_high;
    uint16_t LBASize_high;
} XboxPartitionTableEntry;

typedef struct
{
    unsigned char           Magic[LBA48_Partition_Table_Magic_Size];
    unsigned char           Res0[32];
    XboxPartitionTableEntry TableEntries[XboxPartitionTableEntryCount];
} XboxPartitionTable;

// Partition Table
void PrintFATXPartitionTable(const unsigned char driveId);
void FATXSetBRFR(const unsigned char driveId);
bool FATXCheckMBR(const unsigned char driveId);
void FATXSetMBR(const unsigned char driveId, const XboxPartitionTable *p_table);
void FATXSetInitMBR(const unsigned char driveId);

// Format
unsigned int CalculateClusterSize(const uint64_t lba_size);
void FATXFormatCacheDrives(const unsigned char driveId, const bool verbose);
void FATXFormatDriveC(const unsigned char driveId, const bool verbose);
void FATXFormatDriveE(const unsigned char driveId, const bool verbose);
void FATXFormatExtendedDrive(const unsigned char driveId, const unsigned char partition, const uint64_t lbaStart, const uint64_t lbaSize);

// Open/Close/Check
bool hasFATXSignature(const unsigned char driveId, const uint64_t block);
bool FATXCheckFATXMagic(const unsigned char driveId);
FATXPartition *OpenFATXPartition(const unsigned char driveId, uint64_t partitionOffset, uint64_t partitionSize);
void CloseFATXPartition(FATXPartition* partition);
bool FATXLoadFromDisk(FATXPartition* partition, FATXFILEINFO *fileinfo);

// File/folder OPs
bool LoadFATXFile(FATXPartition *partition, char *filename, FATXFILEINFO *fileinfo);
int FATXListDir(FATXPartition *partition, int clusterId, char **res, int reslen, char *prefix);
int FATXFindDir(FATXPartition *partition, int clusterId, char *dir);
int FATXFindFile(FATXPartition* partition, char* filename, int clusterId, FATXFILEINFO *fileinfo);
int _FATXFindFile(FATXPartition* partition, char* filename, int clusterId, FATXFILEINFO *fileinfo);
void FATXCreateDirectoryEntry(unsigned char * buffer, char *entryName, unsigned int entryNumber, uint32_t cluster);

// Others
int FATXRawRead(const unsigned char driveId, uint64_t sector, uint64_t byte_offset, int byte_len, unsigned char *buf);
void DumpFATXTree(FATXPartition *partition);
void _DumpFATXTree(FATXPartition* partition, int clusterId, int nesting);
void LoadFATXCluster(const FATXPartition* partition, const int clusterId, unsigned char* clusterData);
uint32_t getNextClusterInChain(const FATXPartition* partition, const int clusterId);

#endif //    _BootFATX_H_
