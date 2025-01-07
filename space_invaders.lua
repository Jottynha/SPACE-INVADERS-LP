-- title:   space_invaders
-- author:  Henrique,Joao,Pedro,Jader,Samuel
-- desc:    Derrote os alienigenas
-- site:    website link
-- license: MIT License (change this to your license of choice)
-- version: 0.1
-- script:  lua

-- Definir variáveis globais
player = {x = 100, y = 120, width = 8, height = 8, speed = 2}
bullets = {}
enemies = {}
enemy_speed = 0.1  -- Diminui a velocidade dos inimigos
game_over = false
game_started = false
t = 0
score = 0  -- Variável de pontuação
x = 96
y = 24
enemy_direction = 1  -- Direção do movimento dos inimigos (1: para a direita, -1: para a esquerda)
enemy_move_counter = 0

-- Definindo a posição da área de jogo centralizada
game_area_x = 40
game_area_y = 20
game_area_width = 160
game_area_height = 96

-- Função para criar inimigos em uma formação centralizada
function create_enemies()
    enemies = {}  -- Limpar inimigos anteriores
    local start_x = game_area_x + (game_area_width - 5 * 16) / 2  -- Centraliza os inimigos horizontalmente
    for i = 1, 5 do
        for j = 1, 4 do  -- Ajustando a altura dos inimigos para subir
            table.insert(enemies, {x = start_x + (i - 1) * 16, y = game_area_y + (j - 1) * 12, width = 8, height = 8})
        end
    end
end

-- Função para criar uma nova horda de inimigos
function spawn_enemy_wave()
    local start_x = game_area_x + (game_area_width - 5 * 16) / 2  -- Centraliza os inimigos
    for i = 1, 5 do
        for j = 1, 1 do  -- Nova horda de inimigos no topo
            table.insert(enemies, {x = start_x + (i - 1) * 16, y = game_area_y - 8, width = 8, height = 8})
        end
    end
end

-- Função para desenhar o jogador
function draw_player()
    rect(player.x, player.y, player.width, player.height, 12)  -- cor do jogador
end

-- Função para desenhar as balas
function draw_bullets()
    for i, bullet in ipairs(bullets) do
        rect(bullet.x, bullet.y, bullet.width, bullet.height, 8)  -- cor das balas
    end
end

-- Função para desenhar os inimigos
function draw_enemies()
    for i, enemy in ipairs(enemies) do
        rect(enemy.x, enemy.y, enemy.width, enemy.height, 10)  -- cor dos inimigos (verde claro)
    end
end

-- Função para desenhar o score
function draw_score()
    print("Score: " .. score, 10, 10, 10)  -- Exibir a pontuação no canto superior esquerdo
end

-- Função para desenhar a borda ao redor do jogo
function draw_border()
    rect(game_area_x - 8, game_area_y - 8, game_area_width + 16, game_area_height + 16, 7)  -- borda em volta da área de jogo
end

-- Função para desenhar a tela inicial
function draw_start_screen()
    cls(0)  -- Cor de fundo preta
    -- Fundo decorado
    rect(0, 0, 240, 136, 0)  -- fundo com borda
    rect(10, 10, 220, 116, 7)  -- borda do jogo
    -- Título centralizado
    print("SPACE INVADERS", 80, 40, 10)
    
    -- Informações de controle
    print("CONTROLES:", 60, 60, 9)
    print("Seta Cima/Baixo: Movimenta", 40, 70, 9)
    print("Seta Esquerda/Direita: Movimenta", 40, 80, 9)
    print("Z: Atira", 40, 90, 9)
    print("X: Reiniciar após Game Over", 40, 100, 9)
    print("Pressione qualquer tecla para iniciar", 20, 110, 9)
end

-- Função para desenhar a tela de game over
function draw_game_over_screen()
    cls(0)  -- Cor de fundo preta
    -- Fundo decorado
    rect(0, 0, 240, 136, 0)  -- fundo com borda
    rect(10, 10, 220, 116, 7)  -- borda do jogo
    -- Texto de Game Over
    print("GAME OVER", 100, 60, 8)
    print("Pressione X para reiniciar", 40, 80, 8)  -- Mensagem para reiniciar
end

-- Função para mover o jogador
function move_player()
    if btn(0) then player.y = player.y - player.speed end  -- cima
    if btn(1) then player.y = player.y + player.speed end  -- baixo
    if btn(2) then player.x = player.x - player.speed end  -- esquerda
    if btn(3) then player.x = player.x + player.speed end  -- direita
    -- Limitar o movimento do jogador para não sair da tela
    if player.x < game_area_x then player.x = game_area_x end
    if player.x > game_area_x + game_area_width - player.width then player.x = game_area_x + game_area_width - player.width end
    if player.y < game_area_y then player.y = game_area_y end
    if player.y > game_area_y + game_area_height - player.height then player.y = game_area_y + game_area_height - player.height end
end

-- Função para atirar
function shoot()
    if btnp(4) then  -- botão de atirar (Z)
        table.insert(bullets, {x = player.x + 3, y = player.y, width = 2, height = 4})
    end
end

-- Função para mover as balas
function move_bullets()
    for i, bullet in ipairs(bullets) do
        bullet.y = bullet.y - 4  -- velocidade da bala
        -- Verificar se a bala saiu da tela
        if bullet.y < game_area_y then
            table.remove(bullets, i)
        end
    end
end

-- Função para mover os inimigos
function move_enemies()
    for i, enemy in ipairs(enemies) do
        enemy.x = enemy.x + enemy_direction * enemy_speed
    end

    -- Verificar se algum inimigo chegou nas bordas da tela para inverter a direção
    enemy_move_counter = enemy_move_counter + 1
    if enemy_move_counter > 60 then
        enemy_move_counter = 0
        enemy_direction = -enemy_direction
        -- Descer os inimigos
        for i, enemy in ipairs(enemies) do
            enemy.y = enemy.y + 8
        end
    end

    -- Fim do jogo se inimigos chegarem ao fundo
    for i, enemy in ipairs(enemies) do
        if enemy.y > game_area_y + game_area_height - 8 then
            game_over = true
            break
        end
    end
end

-- Função para verificar colisões
function check_collisions()
    for i, bullet in ipairs(bullets) do
        for j, enemy in ipairs(enemies) do
            if bullet.x < enemy.x + enemy.width and bullet.x + bullet.width > enemy.x and
               bullet.y < enemy.y + enemy.height and bullet.y + bullet.height > enemy.y then
                -- Colisão
                table.remove(bullets, i)
                table.remove(enemies, j)
                score = score + 10  -- Aumenta a pontuação
                break
            end
        end
    end
end

-- Função para desenhar o estado do jogo
function draw_game()
    cls(0)  -- Limpar tela com fundo preto
    draw_border()
    draw_player()
    draw_bullets()
    draw_enemies()
    draw_score()  -- Exibe o score
    if game_over then
        draw_game_over_screen()  -- Exibe a tela de Game Over
    end
end

-- Função principal
function TIC()
    if not game_started then
        draw_start_screen()  -- Exibir tela inicial
        if btnp(4) or btnp(0) or btnp(1) or btnp(2) or btnp(3) then
            game_started = true  -- Iniciar o jogo quando qualquer tecla for pressionada
            create_enemies()  -- Criar inimigos
        end
    else
        if not game_over then
            move_player()
            shoot()
            move_bullets()
            move_enemies()
            check_collisions()

            -- Criar novas hordas de inimigos após um tempo
            if t % 180 == 0 then  -- A cada 3 segundos (180 quadros), uma nova horda
                spawn_enemy_wave()
            end
        elseif btnp(5) then  -- Botão X para reiniciar o jogo
            game_over = false
            score = 0  -- Resetar o score
            create_enemies()
            player.x = 100
            player.y = 120
            bullets = {}
        end
        draw_game()
    end
    t = t + 1  -- Incrementar o contador para animação
end
