%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clear all;
close all;
clc;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%  variables %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
Fs = 40e9;   % sampling frequency
Fb = 1e9;    % Bit rate
Fc = 5e9;    % Carrier frequency
N_of_sym = 20000;
phase_Base = 0; % 46*pi/180;
Noise_level = 30;

%%%%%%%%%%%%%%%%%% Random digital message %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
M = 4; % Alphabet size
x = randi([0 M-1], N_of_sym, 1); % PRBS
Nsamp = Fs/Fb;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%% 4 PSK modulation %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
y = pskmod(x, M);
s = y;
scatterplot(s); title('Symbols to transmit');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%% Rectangular pulse shaping %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
ypulse = rectpulse(y, Nsamp);
scatterplot(s); title('información');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%% Channel Response %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
j = sqrt(-1);
h = [0.0545+j*0.05  0.2832-0.1197*j  -0.7676+0.2788*j  -0.0641-0.0576*j ...
     0.0566-0.2275*j  0.4063-0.0739*j];
h = h/norm(h);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%% Baseband Noisy Signal %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
signal = filter(h,1,s);
scatterplot(signal); title('after of channel');

T = length(signal);
dB = Noise_level;

vn = randn(1,T) + sqrt(-1)*randn(1,T);   % AWGN
vn = vn/norm(vn)*10^(-dB/20)*norm(signal);

SNR = 20*log10(norm(signal)/norm(vn))    % Check SNR

signal = signal + vn';

scatterplot(signal); title('Before CMA equalization');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%% QPSK demodulation %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
z = demodulate(modem.pskdemod(M), signal);

[num_rec, rt_rec] = symerr(x, z);
rt_rec = -1*log10(rt_rec);

disp('%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%')
disp(['Error Rate Rectangular: ' num2str(rt_rec)])
disp('%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%')

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%% Passband Transmission %%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%% Radio Signal %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
F = Fc/Fs;

t_c = 0:1:length(real(ypulse))-1;

In_phase = cos(2*pi*F.*t_c + phase_Base);
Quadrature = sin(2*pi*F.*t_c + phase_Base);

In_phase_np = cos(2*pi*F.*t_c);
Quadrature_np = sin(2*pi*F.*t_c);

figure, plot(In_phase(1:100)); hold on;
plot(real(ypulse(1:100)),'r');

IP_c = real(ypulse)'.*In_phase;
Q_c  = imag(ypulse)'.*Quadrature;

RF_signal = IP_c + Q_c;

figure, stem(RF_signal(1:100));

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%% RF Power Spectrum %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
Ei_u = RF_signal;
Npoints_1 = length(RF_signal);

Ei_F  = fftshift(fft(Ei_u));
Ei_Fa = abs(Ei_F)./length(Ei_F);

Frek_1 = ((-(Npoints_1)/2:(Npoints_1/2-1))).*Fs/Npoints_1;

figure
plot(Frek_1/1e6,20*log10(Ei_Fa),'r');
xlabel('Frequency [MHz]')
ylabel('Power [dB]')
title('Power spectrum of RF received signal')

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%% Passband Noisy Signal %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
T = length(RF_signal);

vn_bp = randn(1,T) + sqrt(-1)*randn(1,T);
vn_bp = vn_bp/norm(vn_bp)*10^(-dB/20)*norm(RF_signal);

SNR_bp = 20*log10(norm(RF_signal)/norm(vn_bp))

Ei_u = RF_signal + vn_bp;

Ei_u = awgn(Ei_u, Noise_level, 0);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%% Receiver %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% 1 Local Oscillator
E_demod_BB  = Ei_u .* In_phase_np;
E_demod_BB2 = Ei_u .* Quadrature_np;

% 2 Low pass filter
Wp = (Fb + 100e6)/(Fs/2);
Ws = (Fb + 250e6)/(Fs/2);

Rp = 3;
Rs = 35;

[n, Ws] = cheb2ord(Wp, Ws, Rp, Rs);
[bRec, aRec] = cheby2(n, Rs, Ws);

figure, freqz(bRec, aRec, 2048, Fs);
title('Pasa bajos');

% 3 Filtering
EBB1 = filter(bRec, aRec, E_demod_BB);
EBB2 = filter(bRec, aRec, E_demod_BB2);

EBB1 = EBB1 - mean(EBB1);
EBB2 = EBB2 - mean(EBB2);

% 4 Power Spectrum
Ei_u = EBB1;
Ei_F  = fftshift(fft(Ei_u));
Ei_Fa = abs(Ei_F)./length(Ei_F);

figure
plot(Frek_1/1e6,20*log10(Ei_Fa),'r');
xlabel('Frequency [MHz]')
ylabel('Power [dB]')
title('Spectrum after demodulator')

% 5 Adjust delay
EBB1 = EBB1(n+floor(n/2):end);
EBB2 = EBB2(n+floor(n/2):end);

% 6 Downsampling
EBB1_downsamp = intdump(EBB1(1:5000*Nsamp), Nsamp);
EBB2_downsamp = intdump(EBB2(1:5000*Nsamp), Nsamp);

RF_signal_recovered = EBB1_downsamp + 1i.*EBB2_downsamp;

scatterplot(RF_signal_recovered);
title('Constellation after demodulation');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%% RF signal demodulation %%%%%%%%%%%%%%%%%%%%%%%%%%%%
RF_signal_received_dem = demodulate(modem.pskdemod(M), RF_signal_recovered);

xm = x(1:length(RF_signal_received_dem))';

[num_RF_received, rt_RF_received] = symerr(xm, RF_signal_received_dem);

rt_RF_received = -1*log10(rt_RF_received);

disp('%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%')
disp(['Bit Error Rate Bandpass transmission: ' num2str(rt_RF_received)])
disp('%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%')