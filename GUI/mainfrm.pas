unit mainfrm;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, IdBaseComponent, IdComponent, IdUDPBase, IdUDPServer,
  IdGlobal, IdSocketHandle, ExtCtrls, AudioIO;

const
  audioChannels = 48;

type
  Tmainform = class(TForm)
    udpserver: TIdUDPServer;
    Timer1: TTimer;
    audioout: TAudioOut;
    channelselector_left: TRadioGroup;
    channelselector_right: TRadioGroup;
    Label5: TLabel;
    GroupBox1: TGroupBox;
    Button1: TButton;
    Button2: TButton;
    Button4: TButton;
    Button3: TButton;
    Button5: TButton;
    GroupBox2: TGroupBox;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    Label6: TLabel;
    Label7: TLabel;
    Label8: TLabel;
    Label10: TLabel;
    Label11: TLabel;
    Label12: TLabel;
    Label13: TLabel;
    Label14: TLabel;
    Label15: TLabel;
    Label16: TLabel;
    Label17: TLabel;
    Label18: TLabel;
    Label19: TLabel;
    Label20: TLabel;
    Label21: TLabel;
    Label22: TLabel;
    Timer2: TTimer;
    packeterror: TLabel;
    packetmissed: TLabel;
    packetmisordered: TLabel;
    GroupBox3: TGroupBox;
    useUdpData: TCheckBox;
    Button8: TButton;
    Label23: TLabel;
    GroupBox4: TGroupBox;
    Label9: TLabel;
    Edit1: TEdit;
    recordformat: TRadioGroup;
    Button6: TButton;
    Button7: TButton;
    transmissioncontrol: TGroupBox;
    audiobufferedit: TEdit;
    Label24: TLabel;
    Label25: TLabel;
    Label27: TLabel;
    procedure Button1Click(Sender: TObject);
    procedure udpserverUDPRead(AThread: TIdUDPListenerThread;
      const AData: TIdBytes; ABinding: TIdSocketHandle);
    procedure Button2Click(Sender: TObject);
    procedure Button4Click(Sender: TObject);
    function audiooutFillBuffer(Buffer: PAnsiChar;
      var Size: Integer): Boolean;
    procedure Timer1Timer(Sender: TObject);
    procedure Button5Click(Sender: TObject);
    procedure Button3Click(Sender: TObject);
    procedure Button6Click(Sender: TObject);
    procedure Button7Click(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure Button8Click(Sender: TObject);
    procedure Timer2Timer(Sender: TObject);
  private
    { Private declarations }
    fileStream: array of TFileStream;
    ringbuffer : array of array of Integer;
    ringbuffer16bit : array of array of SmallInt;
    ringbufferWritePointer, ringbufferReadPointer: cardinal;
    goodPackets, badPackets : integer;
    recordAudio:boolean;
    recordedSamples : cardinal;
    channelCount : integer;
    udpPacketSize : integer;
    sampleRate : cardinal;
    samplesPerPacket : cardinal;
    packetCounter, zpacketCounter, expectedPacketCounter : integer;
    packetDroppedCounter, packetMisorderedCounter : integer;
    numberOfDroppedPackets : integer;
    packetsPerSecond : single;

    audioBufferSize : cardinal;
  public
    { Public declarations }
  end;

var
  mainform: Tmainform;

implementation

{$R *.dfm}

procedure Tmainform.Button1Click(Sender: TObject);
var
  i:integer;
begin
  audiobufferedit.Enabled:=false;

  audioBufferSize := strtoint(audiobufferedit.Text);

  setlength(fileStream, audioChannels);
  setlength(ringbuffer, audioChannels);
  setlength(ringbuffer16bit, audioChannels);
  for i:=0 to audioChannels-1 do
  begin
    setlength(ringbuffer[i], audioBufferSize);
    setlength(ringbuffer16bit[i], audioBufferSize);
  end;

  udpserver.Active := true;
  packetCounter := 0;
  expectedPacketCounter := 0;
  packetDroppedCounter := 0;
  packetMisorderedCounter := 0;
  numberOfDroppedPackets := 0;
end;

procedure Tmainform.udpserverUDPRead(AThread: TIdUDPListenerThread;
  const AData: TIdBytes; ABinding: TIdSocketHandle);
var
  i, c:integer;
  j:integer;
  //audioSample:array[0..audioChannels-1] of SmallInt;
  //audioData:array[0..audioChannels-1] of array[0..3] of byte;
begin
  // each UDP-message contains xx audiosamples with 32 bit and an 4-byte header:
  // AData[0] = 0x4e = N
  // AData[1] = 0x44 = D
  // AData[2] = 0x4e = N
  // AData[3] = 0x47 = G
  // AData[4..5] = 2-byte packetCounter
  // AData[6] = number of transmitted audio-channels and sampleRate in the last two bits 00 = 44.1kHz, 01 = 48kHz, 10=96kHz, 11=192kHz
  // AData[7] = number of samples in this frame

  // first check for the expected header
  if (AData[0] = $4e) and (AData[1] = $44) and (AData[2] = $4e) and (AData[3] = $47) then
  begin
    // we received a good UDP-Payload-Header
    udpPacketSize := length(AData);
    packetCounter := (AData[4] shl 8) + AData[5];

    // check if this packet is in the expected order
    if (packetCounter = expectedPacketCounter) then
    begin
      // packet is in right order
    end else if (packetCounter > expectedPacketCounter) then
    begin
      // we dropped one or more packets
      packetDroppedCounter := packetDroppedCounter + 1;

      if (expectedPacketCounter>0) then
        numberOfDroppedPackets := numberOfDroppedPackets + (packetCounter - expectedPacketCounter);
    end else if (packetCounter < expectedPacketCounter) then
    begin
      packetMisorderedCounter := packetMisorderedCounter + 1;
    end;
    // reset packetDroppedCounter on startup
    if (expectedPacketCounter = 0) then
      packetDroppedCounter := 0;
    expectedPacketCounter := packetCounter + 1;

    // now get some data from the packet
    channelCount := AData[6] and $3f; // in this byte we transmit the number of channels
    // function not implemented, yet
    case ((AData[6] and $c0) shr 6) of
      0: sampleRate := 44100;
      1: sampleRate := 48000;
      2: sampleRate := 96000;
      3: sampleRate := 192000;
    end;
    samplesPerPacket := AData[7];

    // now restore audio-samples
    for i:=0 to samplesPerPacket-1 do
    begin
      // first 8 bytes are for header
      for c:=0 to channelCount-1 do
      begin
        // here is the detailed (but slow) solution to parse the Audio-Samples
        // copy data into new array and cast it as SmallInt (16-bit Audio-Samples)
        //audioData[c][0] := AData[8 + i*8 + 0 + 4*c]; // spare bits = 0
        //audioData[c][1] := AData[8 + i*8 + 1 + 4*c]; // bits 7..0   = LSB
        //audioData[c][2] := AData[8 + i*8 + 2 + 4*c]; // bits 15..8
        //audioData[c][3] := AData[8 + i*8 + 3 + 4*c]; // bits 23..16 = MSB

        // put samples together (playback using TAudioOut only supports 16 bit, so we take the two MSB)
        //audioSample[c] := SmallInt((audioData[c][3] shl 8) + audioData[c][2]); // use audio-bits 23..8

        // store into ringbuffer
        //ringbuffer[c][ringbufferWritePointer] := audioSample[c];

        // this is the more efficient way:
        // cast parts of incoming Byte-Array as SmallInt directly and put it into ringbuffer
        //ringbuffer[c][ringbufferWritePointer] := PSmallInt(@AData[8 + i*8 + 2 + 4*c])^; // just take 2 of 3 bytes. Maybe we can use dithering in a later version
        ringbuffer[c][ringbufferWritePointer] := PInteger(@AData[8 + i*8 + 4*c])^; // copy 32 bit of audio-data into ring-buffer

        if ((ringbufferWritePointer = (audioBufferSize-1)) and recordAudio) then
        begin
          // we reached the last element -> record audio to file
          // write whole ringbuffer to file if ringbufferWritePointer is 0
          if (recordformat.itemindex = 0) then
          begin
            // convert to 16 bit
            for j:=0 to length(ringbuffer[c])-1 do
            begin
              //ringbuffer16bit[c][j] := ringbuffer[c][j] shr 16; // faster, but we are losing data
              ringbuffer16bit[c][j] := ringbuffer[c][j] div 65536;
            end;
            // record 16 bit
            fileStream[c].WriteBuffer(ringbuffer16bit[c][0], audioBufferSize*2);
          end else
          begin
            // record full 32 bit
            fileStream[c].WriteBuffer(ringbuffer[c][0], audioBufferSize*4);
          end;
          if (c = 0) then
          begin
            // increase sample-counter only for one channel
            recordedSamples := recordedSamples + audioBufferSize;
          end;
        end;
      end;

      ringbufferWritePointer := ringbufferWritePointer + 1;
      if (ringbufferWritePointer >= audioBufferSize) then
      begin
        // wrap the pointer around
        ringbufferWritePointer := 0;
      end;
    end;

    goodPackets := goodPackets + 1;
  end else
  begin
    // error: unexpected UDP-Payload-Header
    badPackets := badPackets + 1;
  end;
end;

procedure Tmainform.Button2Click(Sender: TObject);
begin
  udpserver.Send('192.168.42.43', 4023, 'HELLO FPGA!');
end;

procedure Tmainform.Button4Click(Sender: TObject);
begin
  udpserver.Active := false;
  audiobufferedit.Enabled:=true;
end;

function Tmainform.audiooutFillBuffer(Buffer: PAnsiChar;
  var Size: Integer): Boolean;
var
  i, ts : integer;
  pSampleOutputLeft, pSampleOutputRight : ^SmallInt;
  //audioSamplesMono : integer;
  audioSamplesStereo : integer;
  Freq:integer;
begin
  pSampleOutputLeft := Pointer(Buffer);
  pSampleOutputRight := pSampleOutputLeft;
  Inc(pSampleOutputRight);
  //audioSamplesMono := size div 2; // number of 16-bit samples in buffer
  audioSamplesStereo := size div 4; // number of 16-bit samples in buffer

  // copy data to buffer
  if useUdpData.Checked then
  begin
{
    // mono
    for i:=0 to audioSamplesMono - 1 do
    begin
      pSampleOutputLeft^ := ringbuffer[channelselector_left.ItemIndex][ringbufferReadPointer] shr 16; // just take the upper two bytes
      Inc(pSampleOutputLeft);

      ringbufferReadPointer := ringbufferReadPointer + 1;
      if (ringbufferReadPointer >= audioBufferSize) then
      begin
        ringbufferReadPointer := 0;
      end;
    end;
}

    // Stereo
    for i:=0 to audioSamplesStereo-1 do
    begin
      pSampleOutputLeft^ := ringbuffer[channelselector_left.ItemIndex][ringbufferReadPointer] shr 16; // just take the upper two bytes
      pSampleOutputRight^ := ringbuffer[channelselector_right.ItemIndex][ringbufferReadPointer] shr 16; // just take the upper two bytes
      Inc(pSampleOutputLeft, 2);
      Inc(pSampleOutputRight, 2);

      ringbufferReadPointer := ringbufferReadPointer + 1;
      if (ringbufferReadPointer >= audioBufferSize) then
      begin
        ringbufferReadPointer := 0;
      end;
    end;
  end else
  begin
{
    // local demo data (Mono)
    Freq := 1000;
    ts := audioSamplesMono*audioout.FilledBuffers;
    for i:=0 to audioSamplesMono - 1 do
    begin
      pSampleOutputLeft^ := round(8192*Sin((ts+i)/audioout.FrameRate*3.14159*2*Freq));
      Inc(pSampleOutputLeft);
    end;
}
    // local demo data (Stereo)
    Freq := 1000;
    ts := audioSamplesStereo*audioout.FilledBuffers;
    for i:=0 to audioSamplesStereo - 1 do
    begin
      pSampleOutputLeft^ := round(8192*Sin((ts+i)/audioout.FrameRate*3.14159*2*Freq));
      pSampleOutputRight^ := round(8192*Sin((ts+i)/audioout.FrameRate*3.14159*2*1.2*Freq));
      Inc(pSampleOutputLeft, 2);
      Inc(pSampleOutputRight, 2);
    end;
  end;

  Result := True;
end;

procedure Tmainform.Timer1Timer(Sender: TObject);
var
  bufferedSamples:integer;
  bufferInMilliseconds:single;
begin
  label16.Caption := inttostr(udpPacketSize) + ' Bytes';
  label1.caption := inttostr(goodPackets) + ' Packets';
  label2.caption := inttostr(badPackets) + ' Packets';
  label20.Caption := inttostr(packetCounter) + ' Packets';
  if (packetsPerSecond < 1) then
    label22.caption := '...'
  else
    label22.caption := floattostrf(packetsPerSecond, ffFixed, 15, 1) + ' Packets/s';

  label3.Caption := inttostr(ringbufferWritePointer);
  label4.Caption := inttostr(ringbufferReadPointer);

  if (ringbufferWritePointer > ringbufferReadPointer) then
  begin
    // we can calculate the buffered samples directly
    bufferedSamples := ringbufferWritePointer - ringbufferReadPointer;
  end else
  begin
    // WritePointer wrapped around
    bufferedSamples := (audioBufferSize - ringbufferReadPointer) + ringbufferWritePointer;
  end;
  bufferInMilliseconds := (bufferedSamples/48000)*1000;
  label6.Caption := inttostr(round(bufferInMilliseconds)) + 'ms';

  label8.Caption := inttostr(channelCount) + ' Channels';
  label18.Caption := inttostr(sampleRate) + 'Hz';
  label27.Caption := inttostr(samplesPerPacket) + ' Samples';

  packeterror.Caption := inttostr(packetDroppedCounter) + ' dropped';
  packetmissed.Caption := inttostr(numberOfDroppedPackets) + ' missed';
  packetmisordered.Caption := inttostr(packetMisorderedCounter) + ' misordered';
  if ((packetDroppedCounter + packetMisorderedCounter) > 1) then
  begin
    packeterror.font.Color := clRed;
    packetmissed.font.Color := clRed;
    packetmisordered.font.Color := clRed;
  end else
  begin
    packeterror.font.Color := clGreen;
    packetmissed.font.Color := clGreen;
    packetmisordered.font.Color := clGreen;
  end;
end;

procedure Tmainform.Button5Click(Sender: TObject);
begin
  audioout.StopGracefully;
end;

procedure Tmainform.Button3Click(Sender: TObject);
begin
  ringbufferReadPointer := ringbufferWritePointer + (audioBufferSize div 2);
  if (ringbufferReadPointer >= audioBufferSize) then
  begin
    ringbufferReadPointer := ringbufferReadPointer - audioBufferSize;
  end;
  audioout.Start(audioout);
end;

procedure Tmainform.Button6Click(Sender: TObject);
var
  c:integer;
  waveHeader:array[0..67] of byte;
  chunkSize : cardinal;
  subchunk2size : cardinal;
begin
  recordedSamples := 0;
  recordformat.Enabled := false;

  if (recordformat.itemindex = 0) then
  begin
    // 16 bit audio using standard 16-bit WAVE format
    // information about the format: https://github.com/DelphiForBroadcasting/wavefile-delphi/blob/master/Source/audio.wave.reader.pas
    subchunk2size := recordedSamples * 1 * (16 div 8); // Subchunk2Size = NumSamples * NumChannels * BitsPerSample/8
    chunksize := 36 + subchunk2size; // chunkSize = 36 + SubChunk2Size =  4 + (8 + SubChunk1Size) + (8 + SubChunk2Size)

    waveHeader[0] := byte('R'); // chunkID
    waveHeader[1] := byte('I');
    waveHeader[2] := byte('F');
    waveHeader[3] := byte('F');
    move(chunksize, waveHeader[4], 4); // chunkSize = 36 + SubChunk2Size =  4 + (8 + SubChunk1Size) + (8 + SubChunk2Size)
    waveHeader[8] := byte('W'); // Format
    waveHeader[9] := byte('A');
    waveHeader[10] := byte('V');
    waveHeader[11] := byte('E');
    waveHeader[12] := byte('f'); // subChunkID
    waveHeader[13] := byte('m');
    waveHeader[14] := byte('t');
    waveHeader[15] := byte(' ');
    waveHeader[16] := 16; // subChunkSize: Bits per Sample
    waveHeader[17] := 0;
    waveHeader[18] := 0;
    waveHeader[19] := 0;
    waveHeader[20] := 1; // wFormatTag: 0x0001=PCM, 0x0003 IEEE Float, 0xFFFE = WAVE_FORMAT_EXTENSIBLE, followed by Subformat
    waveHeader[21] := 0;
    waveHeader[22] := 1; // nChannels: 1=Mono, 2=Stereo, etc.
    waveHeader[23] := 0;
    move(sampleRate, waveHeader[24], 4); // nSamplesPerSec: 48000 = 0x0000BB80
    waveHeader[28] := 0; // nAvgBytesPerSec = SampleRate * NumChannels * BitsPerSample/8. 48kHz Mono 16bit = 192000 = 0x0002EE00, 48kHz Mono 32bit = 96000 = 0x00017700
    waveHeader[29] := $EE;
    waveHeader[30] := 2;
    waveHeader[31] := 0;
    waveHeader[32] := 4; // nBlockAlign = NumChannels * BitsPerSample/8 = 1 * 32/8
    waveHeader[33] := 0;
    waveHeader[34] := 16; // wBitsPerSample
    waveHeader[35] := 0;

    waveHeader[36] := byte('d'); // subChunk2ID
    waveHeader[37] := byte('a');
    waveHeader[38] := byte('t');
    waveHeader[39] := byte('a');
    waveHeader[40] := 0; // Subchunk2Size
    waveHeader[41] := 0;
    waveHeader[42] := $14;
    waveHeader[43] := 0;

    for c:=0 to channelCount-1 do
    begin
      fileStream[c] := TFileStream.Create(copy(Edit1.Text, 1, length(Edit1.Text)-4) + '_ch' + inttostr(c+1) + '.wav', fmCreate);
      fileStream[c].WriteBuffer(waveHeader, 44);
    end;
  end else
  begin
    // 32 bit audio using WAVE_FORMAT_EXTENSIBLE format
    // information about the format: https://www.mmsp.ece.mcgill.ca/Documents/AudioFormats/WAVE/WAVE.html
    subchunk2size := recordedSamples * 1 * (32 div 8); // Subchunk2Size = NumSamples * NumChannels * BitsPerSample/8
    chunksize := 72 + subchunk2size; // chunkSize = 72 + SubChunk2Size =  4 + (8 + SubChunk1Size) + (8 + SubChunk2Size)

    waveHeader[0] := byte('R'); // chunkID
    waveHeader[1] := byte('I');
    waveHeader[2] := byte('F');
    waveHeader[3] := byte('F');
    move(chunksize, waveHeader[4], 4); // chunkSize = 72 + SubChunk2Size =  4 + (8 + SubChunk1Size) + (8 + SubChunk2Size)
    waveHeader[8] := byte('W'); // Format
    waveHeader[9] := byte('A');
    waveHeader[10] := byte('V');
    waveHeader[11] := byte('E');
    waveHeader[12] := byte('f'); // subChunkID
    waveHeader[13] := byte('m');
    waveHeader[14] := byte('t');
    waveHeader[15] := byte(' ');
    waveHeader[16] := $28; // subChunkSize: Bits per Sample
    waveHeader[17] := 0;
    waveHeader[18] := 0;
    waveHeader[19] := 0;
    waveHeader[20] := $FE; // wFormatTag: 0x0001=PCM, 0x0003 IEEE Float, 0xFFFE = WAVE_FORMAT_EXTENSIBLE, followed by Subformat
    waveHeader[21] := $FF;
    waveHeader[22] := 1; // nChannels: 1=Mono, 2=Stereo, etc.
    waveHeader[23] := 0;
    move(sampleRate, waveHeader[24], 4); // nSamplesPerSec: 48000 = 0x0000BB80
    waveHeader[28] := 0; // nAvgBytesPerSec = SampleRate * NumChannels * BitsPerSample/8. 48kHz Mono 16bit = 192000 = 0x0002EE00, 48kHz Mono 32bit = 96000 = 0x00017700
    waveHeader[29] := $EE;
    waveHeader[30] := 2;
    waveHeader[31] := 0;
    waveHeader[32] := 4; // nBlockAlign = NumChannels * BitsPerSample/8 = 1 * 32/8
    waveHeader[33] := 0;
    waveHeader[34] := 32; // wBitsPerSample
    waveHeader[35] := 0;

    waveHeader[36] := 22; // cbSize
    waveHeader[37] := 0;
    waveHeader[38] := 32; // wValidBitsPerSample
    waveHeader[39] := 0;
    waveHeader[40] := 4; // dwChannelMask
    waveHeader[41] := 0;
    waveHeader[42] := 0;
    waveHeader[43] := 0;
    waveHeader[44] := 1; // SubFormat: 0x0001=PCM, 0x0003 IEEE Float
    waveHeader[45] := 0;
    waveHeader[46] := 0; // next 14 bytes filled with fixed string 0x000000001000800000aa00389b71
    waveHeader[47] := 0;
    waveHeader[48] := 0;
    waveHeader[49] := 0;
    waveHeader[50] := $10;
    waveHeader[51] := 0;
    waveHeader[52] := $80;
    waveHeader[53] := 0;
    waveHeader[54] := 0;
    waveHeader[55] := $aa;
    waveHeader[56] := 0;
    waveHeader[57] := $38;
    waveHeader[58] := $9b;
    waveHeader[59] := $71;

    waveHeader[60] := byte('d'); // subChunk2ID
    waveHeader[61] := byte('a');
    waveHeader[62] := byte('t');
    waveHeader[63] := byte('a');
    waveHeader[64] := 0;
    waveHeader[65] := 0;
    waveHeader[66] := $14;
    waveHeader[67] := 0;
    //move(subchunk2size, waveHeader[64], 4); // Subchunk2Size = NumSamples * NumChannels * BitsPerSample/8

    for c:=0 to channelCount-1 do
    begin
      fileStream[c] := TFileStream.Create(copy(Edit1.Text, 1, length(Edit1.Text)-4) + '_ch' + inttostr(c+1) + '.wav', fmCreate);
      fileStream[c].WriteBuffer(waveHeader, 68);
    end;
  end;

  recordAudio := true;
end;

procedure Tmainform.Button7Click(Sender: TObject);
var
  c:integer;
  chunksize:cardinal;
  subchunk2size:cardinal;
  dwSampleLength : cardinal;
  finalChunkdata:array[0..11] of byte;
begin
  recordAudio := false;
  recordformat.Enabled := true;

  if (recordformat.itemindex = 0) then
  begin
    // finalize 16-bit PCM Wave-File
    subchunk2size := recordedSamples * 1 * (16 div 8); // Subchunk2Size = NumSamples * NumChannels * BitsPerSample/8
    chunksize := 36 + subchunk2size; // chunkSize = 36 + SubChunk2Size =  4 + (8 + SubChunk1Size) + (8 + SubChunk2Size)
    dwSampleLength := 1 * recordedSamples; // dwSampleLength = nChannels * nBlocks

    for c:=0 to channelCount-1 do
    begin
      fileStream[c].Position := 4;
      fileStream[c].WriteBuffer(chunksize, 4);
      fileStream[c].Position := 40;
      fileStream[c].WriteBuffer(subchunk2size, 4);
      fileStream[c].Free;
    end;
  end else
  begin
    // finalize 32-bit PCM Wave-File
    subchunk2size := recordedSamples * 1 * (32 div 8); // Subchunk2Size = NumSamples * NumChannels * BitsPerSample/8
    chunksize := 72 + subchunk2size; // chunkSize = 72 + SubChunk2Size =  4 + (8 + SubChunk1Size) + (8 + SubChunk2Size)
    dwSampleLength := 1 * recordedSamples; // dwSampleLength = nChannels * nBlocks

    finalChunkdata[0] := byte('f'); // chunkID
    finalChunkdata[1] := byte('a');
    finalChunkdata[2] := byte('c');
    finalChunkdata[3] := byte('t');
    finalChunkdata[4] := 4; // chunk size = 4
    finalChunkdata[5] := 0;
    finalChunkdata[6] := 0;
    finalChunkdata[7] := 0;
    move(dwSampleLength, finalChunkdata[8], 4); // dwSampleLength = nChannels * nBlocks

    for c:=0 to channelCount-1 do
    begin
      fileStream[c].WriteBuffer(finalChunkdata, 12);

      fileStream[c].Position := 4;
      fileStream[c].WriteBuffer(chunksize, 4);
      fileStream[c].Position := 64;
      fileStream[c].WriteBuffer(subchunk2size, 4);
      fileStream[c].Free;
    end;
  end;
end;

procedure Tmainform.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  audioout.StopGracefully;
  udpserver.Active:=false;
end;

procedure Tmainform.Button8Click(Sender: TObject);
begin
  packetCounter := 0;
  expectedPacketCounter := 0;
  packetDroppedCounter := 0;
  numberOfDroppedPackets := 0;
  packetMisorderedCounter := 0;
end;

procedure Tmainform.Timer2Timer(Sender: TObject);
begin
  packetsPerSecond := (packetCounter-zpacketCounter)/5;
  zpacketCounter := packetCounter;
end;

end.
