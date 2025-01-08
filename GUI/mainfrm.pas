unit mainfrm;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, IdBaseComponent, IdComponent, IdUDPBase, IdUDPServer,
  IdGlobal, IdSocketHandle, ExtCtrls, AudioIO;

const
  audioBufferSize = 8192*10;
  audioChannels = 2;
  samplesPerPacket = 64;

type
  Tmainform = class(TForm)
    udpserver: TIdUDPServer;
    Timer1: TTimer;
    audioout: TAudioOut;
    channelselector_left: TRadioGroup;
    channelselector_right: TRadioGroup;
    useUdpData: TCheckBox;
    Label5: TLabel;
    GroupBox1: TGroupBox;
    Button1: TButton;
    Button2: TButton;
    Button4: TButton;
    Button3: TButton;
    Button5: TButton;
    Button6: TButton;
    Button7: TButton;
    Edit1: TEdit;
    Label9: TLabel;
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
    packeterror: TLabel;
    Button8: TButton;
    Label21: TLabel;
    Label22: TLabel;
    Timer2: TTimer;
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
    fileStream: TFileStream;
    ringbuffer : array[0..audioChannels-1] of array[0..audioBufferSize-1] of SmallInt;
    ringbufferWritePointer, ringbufferReadPointer: integer;
    goodPackets, badPackets : integer;
    recordAudio:boolean;
    channelCount : integer;
    udpPacketSize : integer;
    sampleRate : integer;
    packetCounter, zpacketCounter, expectedPacketCounter : integer;
    packetDroppedCounter, packetMisorderedCounter : integer;
    numberOfDroppedPackets : integer;
    packetsPerSecond : single;
  public
    { Public declarations }
  end;

var
  mainform: Tmainform;

implementation

{$R *.dfm}

procedure Tmainform.Button1Click(Sender: TObject);
begin
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
  //audioSample:array[0..audioChannels-1] of SmallInt;
  //audioData:array[0..audioChannels-1] of array[0..3] of byte;
begin
  // each UDP-message contains 64 audiosamples for left and right with 32 bit and
  // an 5-byte header 0x0f0f0f0ff0 followed by a 2-byte packet-counter and a
  // status byte containing the number of transmitted audio-channels and
  // sampleRate in the last two bits
  // 00 = 44.1kHz, 01 = 48kHz, 10=96kHz, 11=192kHz
  if (AData[0] = $0f) and (AData[1] = $0f) and (AData[2] = $0f) and (AData[3] = $0f) and (AData[4] = $f0) then
  begin
    // we received a good UDP-Payload-Header

    udpPacketSize := length(AData);
    packetCounter := (AData[5] shl 8) + AData[6];
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
    expectedPacketCounter := packetCounter + 1;

    channelCount := AData[7] and $3f; // in this byte we transmit the number of channels
    // function not implemented, yet
    case ((AData[7] and $c0) shr 6) of
      0: sampleRate := 44100;
      1: sampleRate := 48000;
      2: sampleRate := 96000;
      3: sampleRate := 192000;
    end;

    // restore audio-samples
    for i:=0 to samplesPerPacket-1 do
    begin
      // first 8 bytes are for header
      for c:=0 to audioChannels-1 do
      begin
{
        // here is the detailed (but slow) solution to parse the Audio-Samples
        // copy data into new array and cast it as SmallInt (16-bit Audio-Samples)
        audioData[c][0] := AData[8 + i*8 + 0 + 4*c]; // spare bits = 0
        audioData[c][1] := AData[8 + i*8 + 1 + 4*c]; // bits 7..0   = LSB
        audioData[c][2] := AData[8 + i*8 + 2 + 4*c]; // bits 15..8
        audioData[c][3] := AData[8 + i*8 + 3 + 4*c]; // bits 23..16 = MSB

        // put samples together (playback using TAudioOut only supports 16 bit, so we take the two MSB)
        audioSample[c] := SmallInt((audioData[c][3] shl 8) + audioData[c][2]); // use audio-bits 23..8

        // store into ringbuffer
        ringbuffer[c][ringbufferWritePointer] := audioSample[c];
}
        // this is the more efficient way:
        // cast parts of incoming Byte-Array as SmallInt directly and put it into ringbuffer
		ringbuffer[c][ringbufferWritePointer] := PSmallInt(@AData[8 + i*8 + 2 + 4*c])^; // just take 2 of 3 bytes. Maybe we can use dithering in a later version
      end;

      ringbufferWritePointer := ringbufferWritePointer + 1;
      if (ringbufferWritePointer >= audioBufferSize) then
      begin
        ringbufferWritePointer := 0;

        // record audio to file
        if recordAudio then
        begin
          // write whole ringbuffer to file if ringbufferWritePointer is 0
          fileStream.Write(ringbuffer[0][0], audioBufferSize);
        end;
      end;
    end;

    // when using a ringbuffer with 32-bit, we could use a direct copy:
    move(AData[8], ringbuffer[0][ringbufferWritePointer], );

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
      pSampleOutputLeft^ := ringbuffer[channelselector_left.ItemIndex][ringbufferReadPointer];
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
      pSampleOutputLeft^ := ringbuffer[channelselector_left.ItemIndex][ringbufferReadPointer];
      pSampleOutputRight^ := ringbuffer[channelselector_right.ItemIndex][ringbufferReadPointer];
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

  if ((packetDroppedCounter + packetMisorderedCounter) > 1) then
  begin
    packeterror.font.Color := clRed;
    packeterror.Caption := inttostr(packetDroppedCounter) + ' dropped (' + inttostr(numberOfDroppedPackets) + ' missed) | ' + inttostr(packetMisorderedCounter) + ' misordered';
  end else
  begin
    packeterror.font.Color := clGreen;
    packeterror.Caption := 'Packet-Quality is good';
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
begin
  fileStream := TFileStream.Create(Edit1.Text, fmCreate);
  recordAudio := true;
end;

procedure Tmainform.Button7Click(Sender: TObject);
begin
  recordAudio := false;
  fileStream.Free;
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
  packetMisorderedCounter := 0;
end;

procedure Tmainform.Timer2Timer(Sender: TObject);
begin
  packetsPerSecond := (packetCounter-zpacketCounter)/5;
  zpacketCounter := packetCounter;
end;

end.
