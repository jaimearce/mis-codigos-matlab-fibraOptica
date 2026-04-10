function DispersionCromatica(R, sec, Dz, C, b2, b3)

    fprintf('Procesando...\n');

    %%%%%%%%%%%%%%%%%%%%% Parámetros básicos %%%%%%%%%%%%%%%%%%%%%
    Tb = 1/R;                      % Tiempo de bit
    n_bits = length(sec);          % Número de bits
    Fs = 64/Tb;                    % Frecuencia de muestreo
    Ts = 1/Fs;                     % Periodo de muestreo

    %%%%%%%%%%%%%%%%%%%%% Discretización correcta %%%%%%%%%%%%%%%%%
    Nmpb = round(Tb/Ts);           % Muestras por bit (ENTERO)
    Nmps = Nmpb * n_bits;          % Total de muestras

    %%%%%%%%%%%%%%%%%%%%% Pulso Gaussiano %%%%%%%%%%%%%%%%%%%%%%%%
    To = Tb/8;
    t_pulse = linspace(-Tb/2, Tb/2, Nmpb);   % Vector consistente

    p_gauss = zeros(1, Nmps);

    for k = 1:n_bits
        At = (t_pulse/To).^2;

        p_gauss((k-1)*Nmpb + 1 : k*Nmpb) = ...
            sec(k) * exp(-0.5 * (1 + 1i*C) * At);
    end

    %%%%%%%%%%%%%%%%%%%%% Eje de tiempo global %%%%%%%%%%%%%%%%%%%
    t1 = 0 : Ts : (Nmps-1)*Ts;

    %%%%%%%%%%%%%%%%%%%%% Dominio en frecuencia %%%%%%%%%%%%%%%%%%
    n = 0:Nmps-1;
    w = 2*pi * (n - Nmps/2) * Fs / Nmps;

    %%%%%%%%%%%%%%%%%%%%% Canal con dispersión %%%%%%%%%%%%%%%%%%%
    Hd = exp( 1i * 0.5 * b2 * Dz * w.^2 ...
            - 1i * (b3 * Dz / 6) * w.^3 );

    %%%%%%%%%%%%%%%%%%%%% Aplicar dispersión %%%%%%%%%%%%%%%%%%%%%
    AouF = fftshift(fft(p_gauss)) .* Hd;
    Aou = ifft(fftshift(AouF));

    %%%%%%%%%%%%%%%%%%%%% Gráfica %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    figure;
    plot(t1, abs(p_gauss), 'r', 'LineWidth', 1.5); hold on;
    plot(t1, abs(Aou), 'g', 'LineWidth', 1.5);

    xlabel('Tiempo (s)');
    ylabel('Amplitud');
    legend('Pulso Gausiano','iFFt');
    title('Dispersión Cromática en Fibra Óptica');
    grid on;
    %%%%%%%%%%%%%%%%%%%%% Mostrar parámetros en la gráfica %%%%%%%
    titulo = sprintf(['Dispersión Cromática\n', ...
        'R = %.2e bps   |   Dz = %.2e m   |   C = %.2f'], R, Dz, C);
    title(titulo);
    %ESTILO PARA LATEX / PUBLICACIÓN
    set(gca, 'FontSize', 12);   % tamaño de letra de ejes
    set(gcf, 'Color', 'w');     % fondo blanco

end