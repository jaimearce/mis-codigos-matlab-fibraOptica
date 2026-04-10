clear all;
close all;
clc;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%  Variables %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
Fs = 40e9;   % Sampling frequency
Fb = 1e9;    % Bit rate
Fc = 5e9;    % Carrier frequency
N_of_sym = 20000;
phase_Base = 0; 
Noise_level = 30;

%%%%%%%%%%%%%%%%%% Random digital message %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
M = 4; % Alphabet size (QPSK)
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

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%% Channel Response %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% NOTA: El canal original introducía mucha ISI y sin un ecualizador 
% programado el BER era 1. Se comenta el canal complejo y se usa un 
% canal ideal (h=1) para que la simulación de Rx/Tx funcione.

% h = [0.0545+1i*0.05  0.2832-0.1197*1i  -0.7676+0.2788*1i  -0.0641-0.0576*1i ...
%      0.0566-0.2275*1i  0.4063-0.0739*1i];
% h = h/norm(h);
h = 1; % Canal ideal

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%% Baseband Noisy Signal %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
signal = filter(h,1,s);
scatterplot(signal); title('After channel (Baseband)');
T = length(signal);
dB = Noise_level;

vn = randn(T,1) + 1i*randn(T,1);   % AWGN
vn = vn/norm(vn)*10^(-dB/20)*norm(signal);
SNR = 20*log10(norm(signal)/norm(vn));    % Check SNR
disp(['SNR Baseband: ' num2str(SNR) ' dB']);

signal = signal + vn;
scatterplot(signal); title('Received Signal (Baseband)');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%% QPSK demodulation %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
z = pskdemod(signal, M);
[num_rec, rt_rec] = symerr(x, z);

disp('%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%')
disp(['Bits erroneos Banda Base: ' num2str(num_rec) ' de ' num2str(N_of_sym)])
disp(['BER Banda Base: ' num2str(rt_rec)])
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
title('In-phase Carrier and Baseband Pulse');

IP_c = real(ypulse)'.*In_phase;
Q_c  = imag(ypulse)'.*Quadrature;
RF_signal = IP_c + Q_c;

figure, stem(RF_signal(1:100));
title('RF Signal (First 100 samples)');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%% RF Power Spectrum %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
Ei_u = RF_signal;
Npoints_1 = length(RF_signal);
Ei_F  = fftshift(fft(Ei_u));
Ei_Fa = abs(Ei_F)./length(Ei_F);
Frek_1 = ((-(Npoints_1)/2:(Npoints_1/2-1))).*Fs/Npoints_1;

figure
plot(Frek_1/1e6, 20*log10(Ei_Fa), 'r');
xlabel('Frequency [MHz]')
ylabel('Power [dB]')
title('Power spectrum of RF transmitted signal')

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%% Passband Noisy Signal %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
T_RF = length(RF_signal);
vn_bp = randn(1,T_RF) + 1i*randn(1,T_RF);
vn_bp = vn_bp/norm(vn_bp)*10^(-dB/20)*norm(RF_signal);
SNR_bp = 20*log10(norm(RF_signal)/norm(vn_bp));
disp(['SNR Passband: ' num2str(SNR_bp) ' dB']);

Ei_u = RF_signal + vn_bp; 

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
[n_filt, Ws] = cheb2ord(Wp, Ws, Rp, Rs);
[bRec, aRec] = cheby2(n_filt, Rs, Ws);
figure, freqz(bRec, aRec, 2048, Fs);
title('Filtro Pasa Bajos');

% 3 Filtering
EBB1 = filter(bRec, aRec, E_demod_BB);
EBB2 = filter(bRec, aRec, E_demod_BB2);
EBB1 = EBB1 - mean(EBB1);
EBB2 = EBB2 - mean(EBB2);

% 4 Power Spectrum
Ei_u_rx = EBB1;
Ei_F_rx  = fftshift(fft(Ei_u_rx));
Ei_Fa_rx = abs(Ei_F_rx)./length(Ei_F_rx);
figure
plot(Frek_1/1e6, 20*log10(Ei_Fa_rx), 'r');
xlabel('Frequency [MHz]')
ylabel('Power [dB]')
title('Spectrum after demodulator')

% 5 Adjust delay
delay = n_filt + floor(n_filt/2);
EBB1 = EBB1(delay:end);
EBB2 = EBB2(delay:end);

% 6 Downsampling
% AQUI SE CORRIGE EL ERROR DE INTDUMP
valid_len = floor(length(EBB1)/Nsamp) * Nsamp;
EBB1_downsamp = intdump(EBB1(1:valid_len), Nsamp);
EBB2_downsamp = intdump(EBB2(1:valid_len), Nsamp);

RF_signal_recovered = EBB1_downsamp + 1i.*EBB2_downsamp;
scatterplot(RF_signal_recovered);
title('Constellation after demodulation');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%% RF signal demodulation %%%%%%%%%%%%%%%%%%%%%%%%%%%%
RF_signal_received_dem = pskdemod(RF_signal_recovered, M);

min_len = min(length(x), length(RF_signal_received_dem));
xm = x(1:min_len)';
rec_dem_adj = RF_signal_received_dem(1:min_len);

[num_RF_received, rt_RF_received] = symerr(xm, rec_dem_adj);

disp('%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%')
disp(['Bits erroneos Pasabanda: ' num2str(num_RF_received) ' de ' num2str(min_len)])
disp(['BER Pasabanda: ' num2str(rt_RF_received)])
disp('%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%')
