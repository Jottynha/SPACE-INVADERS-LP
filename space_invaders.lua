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
special_weapon = {x = nil, y = nil, width = 8, height = 8, active = false, duration = 180, timer = 0}
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
    local enemy_count = 5  -- Número de inimigos a gerar
    local max_attempts = 50  -- Tentativas para evitar colisões

    for _ = 1, enemy_count do
        local spawned = false
        local attempts = 0

        while not spawned and attempts < max_attempts do
            attempts = attempts + 1

            -- Gera coordenadas aleatórias no topo da tela
            local new_enemy = {
                x = math.random(game_area_x, game_area_x + game_area_width - 8), -- Aleatório na largura
                y = game_area_y - 7,  -- Sempre no topo da tela
                width = 8,
                height = 8,
                speed = math.random(1, 3) -- Velocidade aleatória para descer
            }

            -- Verifica se há colisão com outros inimigos
            local collision = false
            for _, enemy in ipairs(enemies) do
                if new_enemy.x < enemy.x + enemy.width and new_enemy.x + new_enemy.width > enemy.x and
                   new_enemy.y < enemy.y + enemy.height and new_enemy.y + new_enemy.height > enemy.y then
                    collision = true
                    break
                end
            end

            -- Se não houver colisão, adiciona o inimigo à lista
            if not collision then
                table.insert(enemies, new_enemy)
                spawned = true
            end
        end

        -- Caso não consiga posicionar após várias tentativas
        if attempts >= max_attempts then
            print("Falha ao posicionar todos os inimigos sem colisões.")
        end
    end
end



-- Função para desenhar o jogador com sprite
function draw_player()
    spr(player.sprite, player.x, player.y, 0, 1, 0, 0, 1, 1) 
end

-- Função para desenhar as balas
function draw_bullets()
    if special_weapon.active then
        for i, bullet in ipairs(bullets) do
            rect(bullet.x, bullet.y, bullet.width, bullet.height, 2)  -- cor das balas
        end  

    else
        for i, bullet in ipairs(bullets) do
            rect(bullet.x, bullet.y, bullet.width, bullet.height, 8)  -- cor das balas
        end
    end
end

-- Função para desenhar os inimigos
function draw_enemies()
    for i, enemy in ipairs(enemies) do
        spr(1, enemy.x, enemy.y, 0, 1, 0, 0, 1, 1)  -- cor dos inimigos (verde claro)
    end
end

function draw_special_weapon()
    if special_weapon.x then
        spr(2, special_weapon.x, special_weapon.y, 0, 1, 0, 0, 1, 1)
    end
end


-- Função para desenhar o score
function draw_score()
    print("Score: " .. score, 10, 10, 10)  -- Exibir a pontuação no canto superior esquerdo
    if(special_weapon.active) then 
        print("Special Weapon Active", 10, 20, 10) 
    end
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
    print("CONTROLES:", 60, 60, 10)
    print("Seta Cima/Baixo: Movimenta", 40, 70, 10)
    print("Seta Esquerda/Direita: Movimenta", 40, 80, 10)
    print("Z: Atira", 40, 90, 10)
    print("X: Reiniciar após Game Over", 40, 100, 10)
    print("Pressione qualquer tecla para iniciar", 20, 110, 10)
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

function spawn_special_weapon()
        special_weapon.x = game_area_x + math.random(0, game_area_width - special_weapon.width)
        special_weapon.y = game_area_y + math.random(0, game_area_height - special_weapon.height)
end


-- Função para atirar
function shoot()
    if btnp(4) then  -- botão de atirar (Z)
        table.insert(bullets, {x = player.x + 3, y = player.y, width = 2, height = 4})
    end
end

function shoot_special()
    if btnp(4) then  -- Botão de disparo (Z)
        table.insert(bullets, {x = player.x + 3, y = player.y, width = 2, height = 4}) -- Disparo central
        table.insert(bullets, {x = player.x - 3, y = player.y, width = 2, height = 4, dx = -1, dy = -1}) -- Diagonal esquerda
        table.insert(bullets, {x = player.x + 9, y = player.y, width = 2, height = 4, dx = 1, dy = -1}) -- Diagonal direita
    end
end


function move_bullets()
    for i, bullet in ipairs(bullets) do
        bullet.y = bullet.y - 4  -- Movimento vertical
        if bullet.dx then bullet.x = bullet.x + bullet.dx * 2 end -- Movimento diagonal
        if bullet.dy then bullet.y = bullet.y + bullet.dy * 2 end -- Movimento diagonal
        -- Verificar se a bala saiu da tela
        if bullet.y < game_area_y or bullet.x < game_area_x or bullet.x > game_area_x + game_area_width then
            table.remove(bullets, i)
        end
    end
end

function update_weapon()
    if special_weapon.active then
        special_weapon.timer = special_weapon.timer - 1
        if special_weapon.timer <= 0 then
            special_weapon.active = false
        end
    end
    
    if special_weapon.active then
        shoot_special()  -- Ativar disparo especial
    else
        shoot()  -- Disparo normal
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

function check_special_weapon_collision()
    if special_weapon.x and player.x < special_weapon.x + special_weapon.width and
       player.x + player.width > special_weapon.x and
       player.y < special_weapon.y + special_weapon.height and
       player.y + player.height > special_weapon.y then
        special_weapon.active = true
        special_weapon.timer = special_weapon.duration
        special_weapon.x = nil  -- Remove o item da tela
        special_weapon.y = nil
    end
end

-- Função para verificar colisões
function check_collisions()
    -- Verifica colisões entre balas e inimigos
    for i, bullet in ipairs(bullets) do
        for j, enemy in ipairs(enemies) do
            if bullet.x < enemy.x + enemy.width and bullet.x + bullet.width > enemy.x and
               bullet.y < enemy.y + enemy.height and bullet.y + bullet.height > enemy.y then
                -- Colisão entre bala e inimigo
                table.remove(bullets, i)
                table.remove(enemies, j)
                score = score + 10  -- Aumenta a pontuação
                break
            end
        end
    end

    -- Verifica colisões entre o jogador e inimigos
    for i, enemy in ipairs(enemies) do
        if player.x < enemy.x + enemy.width and player.x + player.width > enemy.x and
           player.y < enemy.y + enemy.height and player.y + player.height > enemy.y then
            -- Colisão entre jogador e inimigo
            print("Game Over")
            game_over = true
            break
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
    draw_special_weapon()
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
            update_weapon()
            check_special_weapon_collision()    
            if t % 120 == 0 then  -- A cada 3 segundos , uma nova horda
                spawn_enemy_wave()
            end
            if t % 600 == 0 then  -- A cada 10 segundos , uma nova horda
                spawn_special_weapon()
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
