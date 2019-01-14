# Basic structs and typedefs
# ==========================

type
  FnPtr* = proc () {.noconv.}          ## void foo() function pointer, used for interrupt handlers etc.
  FnVI* = proc (x:int) {.noconv.}      ## void foo(int x) function pointer
  FnII* = proc (x:int):int {.noconv.}  ## int foo(int x) function pointer

# To be used with codegenDecl pragma:
const
  IWRAM_DATA = "IWRAM_DATA $# $#"    ## Put variable in IWRAM (default).
  EWRAM_DATA = "EWRAM_DATA $# $#"    ## Put variable in EWRAM.
  EWRAM_BSS = "EWRAM_BSS $# $#"      ## Put non-initialized variable in EWRAM.
  IWRAM_CODE = "IWRAM_CODE $# $#$#"  ## Put procedure in IWRAM.
  EWRAM_CODE = "EWRAM_CODE $# $#$#"  ## Put procedure in EWRAM.

# Note: in the next Nim release we might be able to use macros as pragmas for var/let symbols
# see https://github.com/nim-lang/Nim/commit/044cef152f6006927a905d69dc527cada8206b0f
# Which would allow us to do
#   var foo {.ewram.}: int
# but codegenDecl is good enough for now

# Unfortunately these can't be exported
# {.pragma:iwramData, codegenDecl: "IWRAM_DATA $# $#".}    ## Put variable in IWRAM (default).
# {.pragma:ewramData, codegenDecl: "EWRAM_DATA $# $#".}    ## Put variable in EWRAM.
# {.pragma:ewramBss, codegenDecl: "EWRAM_BSS $# $#".}      ## Put non-initialized variable in EWRAM.
# {.pragma:iwramCode, codegenDecl: "IWRAM_CODE $# $#$#".}  ## Put procedure in IWRAM.
# {.pragma:ewramCode, codegenDecl: "EWRAM_CODE $# $#$#".}  ## Put procedure in EWRAM.
# TODO: Figure out how to do {.align4.} {.align:N.} pragmas, if I need them
# e.g. {.pragma: align4, codegenDecl: "$# $# ALIGN4".}
# but that only seems to work for variables, not types??

type
  Block* {.importc: "BLOCK", header: "tonc.h", bycopy.} = object
    ## 8-word type for fast struct-copies
    data* {.importc: "data".}: array[8, uint32]

type
  Fixed* = distinct int32   ## Fixed point type, "24.8"

type
  Color* = uint16         ## Type for colors

type
  ScrEntry* = uint16    ## Type for screen entries
  ScrAffEntry* = uint8  ## Type for affine screen entries

type
  Tile* = Tile4
  
  Tile4* {.importc: "TILE4", header: "tonc.h", bycopy.} = object
    ## 4bpp tile type, for easy indexing and copying of 4-bit tiles
    data* {.importc: "data".}: array[8, uint32]
    
  Tile8* {.importc: "TILE8", header: "tonc.h", bycopy.} = object
    ## 8bpp tile type, for easy indexing and copying of 8-bit tiles
    data* {.importc: "data".}: array[16, uint32]

type
  ObjAffineSource* = AffSrc
  BgAffineSource* = AffSrcEx
  ObjAffineDest* = AffDst
  BgAffineDest* = AffDstEx
  
  AffSrc* {.importc: "AFF_SRC", header: "tonc.h", bycopy.} = object
    ## Simple scale-rotation source struct.
    ## This can be used with ObjAffineSet, and several of tonc's affine functions
    sx* {.importc: "sx".}: int16          ## Horizontal zoom (8.8f)
    sy* {.importc: "sy".}: int16          ## Vertical zoom (8.8f)
    alpha* {.importc: "alpha".}: uint16   ## Counter-clockwise angle (range [0, 0xFFFF])
  
  AffSrcEx* {.importc: "AFF_SRC_EX", header: "tonc.h", bycopy.} = object
    ## Extended scale-rotate source struct
    ## This is used to scale/rotate around an arbitrary point. See tonc's main text for all the details.
    texX* {.importc: "tex_x".}: int32   ## Texture-space anchor, x coordinate  (.8f)
    texY* {.importc: "tex_y".}: int32   ## Texture-space anchor, y coordinate  (.8f)
    scrX* {.importc: "scr_x".}: int16   ## Screen-space anchor, x coordinate  (.0f)
    scrY* {.importc: "scr_y".}: int16   ## Screen-space anchor, y coordinate  (.0f)
    sx* {.importc: "sx".}: int16        ## Horizontal zoom (8.8f)
    sy* {.importc: "sy".}: int16        ## Vertical zoom (8.8f)
    alpha* {.importc: "alpha".}: uint16 ## Counter-clockwise angle (range [0, 0xFFFF])
  
  AffDst* {.importc: "AFF_DST", header: "tonc.h", bycopy.} = object
    ## Simple scale-rotation destination struct, BG version.
    ## This is a P-matrix with continuous elements, like the BG matrix.
    ## It can be used with ObjAffineSet.
    pa* {.importc: "pa".}: int16
    pb* {.importc: "pb".}: int16
    pc* {.importc: "pc".}: int16
    pd* {.importc: "pd".}: int16

  AffDstEx* {.importc: "AFF_DST_EX", header: "tonc.h", bycopy.} = object
    ## Extended scale-rotate destination struct
    ## This contains the P-matrix and a fixed-point offset, the
    ##  combination can be used to rotate around an arbitrary point.
    ##  Mainly intended for BgAffineSet, but the struct can be used
    ##  for object transforms too.
    pa* {.importc: "pa".}: int16
    pb* {.importc: "pb".}: int16
    pc* {.importc: "pc".}: int16
    pd* {.importc: "pd".}: int16
    dx* {.importc: "dx".}: int32
    dy* {.importc: "dy".}: int32


## Memory map structs
## ==================

## Tertiary types
## These types are used for memory mapping of VRAM, affine registers 
##  and other areas that would benefit from logical memory mapping.

## Regular bg points; range: :0010 - :001F

type
  BgPoint* = Point16
  Point16* {.importc: "POINT16", header: "tonc.h", bycopy.} = object
    x* {.importc: "x".}: int16
    y* {.importc: "y".}: int16

type BgAffine* = AffDstEx
  ## Affine parameters for backgrounds; range : 0400:0020 - 0400:003F

type
  DmaRec* {.importc: "DMA_REC", header: "tonc.h", bycopy.} = object
    ##  DMA struct; range: 0400:00B0 - 0400:00DF
    src* {.importc: "src".}: pointer
    dst* {.importc: "dst".}: pointer
    cnt* {.importc: "cnt".}: uint32

  TmrRec* {.importc: "TMR_REC", header: "tonc.h", bycopy.} = object
    ## Timer struct, range: 0400:0100 - 0400:010F
    ## note: The attribute is required, because union's counted as u32 otherwise.
    start* {.importc: "start".}: uint16
    count* {.importc: "count".}: uint16  # start and count are actually union fields? does this still work?
    cnt* {.importc: "cnt".}: uint16

type Palbank* = array[16, Color]
  ## Palette bank type, for 16-color palette banks


## VRAM array types
## These types allow VRAM access as arrays or matrices in their most natural types.
type
  Screenline* = ptr array[32, ScrEntry]
  ScreenMat* = ptr array[32, ptr array[32, ScrEntry]]
  Screenblock* = ptr array[1024, ScrEntry]
  M3Line* = ptr array[240, Color]
  M4Line* = ptr array[240, uint8]  ## NOTE: u8, not u16!!
  M5Line* = ptr array[160, Color]
  Charblock* = ptr array[512, Tile]
  Charblock8* = ptr array[256, Tile8]

type
  ObjAttr* {.importc: "OBJ_ATTR", header: "tonc.h", bycopy.} = object
    ## Object attributes.
    ## Note: attribute 3 is padding for the interlace with OBJ_AFFINE.
    ##  If not using affine objects, it can be used as a free field
    attr0* {.importc: "attr0".}: uint16
    attr1* {.importc: "attr1".}: uint16
    attr2* {.importc: "attr2".}: uint16
    fill* {.importc: "fill".}: int16
  
  ObjAffine* {.importc: "OBJ_AFFINE", header: "tonc.h", bycopy.} = object
    ## Object affine parameters.
    ## [Padding fields are ommitted, it's OK as long as they exist on the C side]
    # fill0* {.importc: "fill0".}: array[3, uint16]
    pa* {.importc: "pa".}: int16
    # fill1* {.importc: "fill1".}: array[3, uint16]
    pb* {.importc: "pb".}: int16
    # fill2* {.importc: "fill2".}: array[3, uint16]
    pc* {.importc: "pc".}: int16
    # fill3* {.importc: "fill3".}: array[3, uint16]
    pd* {.importc: "pd".}: int16
  
  ObjAttrPtr* = ptr ObjAttr
    ## Pointer to object attributes.
    
  ObjAffinePtr* = ptr ObjAffine
    ## Pointer to object affine parameters.


# sizeof currently doesn't work with object types at compile time
# and there is no pragma to inform the compiler otherwise
# so we need these constants:
const
  sizeof_Block* = 8 * sizeof(uint32)
  sizeof_Tile* = 8 * sizeof(uint32)
  sizeof_Tile8* = 16 * sizeof(uint32)
  sizeof_AffSrc* = 3 * sizeof(int16)
  sizeof_AffSrcEx* = 2 * sizeof(int32) + 5 * sizeof(int16)
  sizeof_AffDst* = 4 * sizeof(int16)
  sizeof_AffDstEx* = 4 * sizeof(int16) + 2 * sizeof(int32)
  sizeof_Point16* = 2 * sizeof(int16)
  sizeof_DmaRec* = 2 * sizeof(pointer) + sizeof(uint32)   # TODO: check sizeof pointer is correct at compile time
  sizeof_TmrRec* = 3 * sizeof(uint16)
  sizeof_Palbank* = 16 * sizeof(Color)
  sizeof_Screenline* = 32 * sizeof(ScrEntry)
  sizeof_ScreenMat* = 32 * 32 * sizeof(ScrEntry)
  sizeof_Screenblock* = 1024 * sizeof(ScrEntry)
  sizeof_M3Line* = 240 * sizeof(Color)
  sizeof_M4Line* = 240 * sizeof(uint8)
  sizeof_M5Line* = 160 * sizeof(Color)
  sizeof_Charblock* = 512 * sizeof_Tile
  sizeof_Charblock8* = 256 * sizeof_Tile8
  sizeof_ObjAttr* = 8
  sizeof_ObjAffine* = 8
  