# -*- coding: utf-8 -*-
"""
Генерация QR-кодов для страницы "Социальные сети" (assets/qr/*.png).

Каждый QR создаётся с уровнем коррекции ошибок H (выдерживает закрытие
до ~30% площади), в центр на белой подложке вставляется простой логотип,
нарисованный средствами PIL. Подложка занимает около 22% стороны QR
(~5% площади), поэтому код остаётся читаемым.

Запуск (из корня проекта):
    pip install "qrcode[pil]" pillow
    python tools/make_qr.py

URL-ы совпадают с SOCIAL_LINKS в js/screens-home.jsx.
"""
import os

import qrcode
from PIL import Image, ImageDraw, ImageFont
from qrcode.constants import ERROR_CORRECT_H

# Размер итоговой картинки в пикселях
SIZE = 600
# Доля стороны QR, которую занимает белая подложка с логотипом
LOGO_RATIO = 0.22

# Куда сохранять результат (папка assets/qr относительно корня проекта)
OUT_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'assets', 'qr')

# Ссылки — те же, что в SOCIAL_LINKS (js/screens-home.jsx)
LINKS = {
    'site': 'https://mck-ktits.ru',
    'max': 'https://max.ru/id1660014523_gos',
    'vk': 'https://vk.com/mck_ktits',
    'inst': 'https://www.instagram.com/ktits.ru',
}


def make_base_qr(url):
    """Строит базовый QR-код (чёрный по белому) размером SIZE x SIZE."""
    qr = qrcode.QRCode(error_correction=ERROR_CORRECT_H, box_size=10, border=4)
    qr.add_data(url)
    qr.make(fit=True)
    img = qr.make_image(fill_color='black', back_color='white').convert('RGB')
    return img.resize((SIZE, SIZE), Image.NEAREST)


def draw_vk(draw, x, y, s):
    """VK — синий круг с белой надписью VK."""
    draw.ellipse([x, y, x + s, y + s], fill=(0, 119, 255))
    font = load_font(int(s * 0.42))
    draw.text((x + s / 2, y + s / 2), 'VK', font=font, fill='white', anchor='mm')


def draw_inst(draw, x, y, s):
    """Instagram — скруглённый квадрат с камерой (круг и объектив)."""
    r = int(s * 0.22)  # радиус скругления углов
    draw.rounded_rectangle([x, y, x + s, y + s], radius=r, fill=(228, 64, 95))
    # корпус камеры — белая рамка
    m = int(s * 0.16)
    lw = max(2, int(s * 0.06))
    draw.rounded_rectangle([x + m, y + m, x + s - m, y + s - m], radius=int(r * 0.7),
                           outline='white', width=lw)
    # объектив
    c = x + s / 2
    lr = s * 0.17
    draw.ellipse([c - lr, y + s / 2 - lr, c + lr, y + s / 2 + lr], outline='white', width=lw)
    # вспышка — точка справа сверху
    fr = s * 0.045
    fx, fy = x + s - m - s * 0.12, y + m + s * 0.12
    draw.ellipse([fx - fr, fy - fr, fx + fr, fy + fr], fill='white')


def draw_max(draw, x, y, s):
    """MAX — синяя метка (круг с хвостиком) с белой буквой M."""
    # круг
    draw.ellipse([x, y, x + s, y + s * 0.88], fill=(48, 92, 240))
    # хвостик метки снизу
    cx = x + s / 2
    draw.polygon([(cx - s * 0.14, y + s * 0.72),
                  (cx + s * 0.14, y + s * 0.72),
                  (cx, y + s)], fill=(48, 92, 240))
    font = load_font(int(s * 0.44))
    draw.text((cx, y + s * 0.42), 'M', font=font, fill='white', anchor='mm')


def draw_site(draw, x, y, s):
    """Сайт — глобус: круг с меридианом и параллелями."""
    lw = max(2, int(s * 0.07))
    cx, cy = x + s / 2, y + s / 2
    r = s / 2 - lw
    color = (23, 105, 200)
    draw.ellipse([cx - r, cy - r, cx + r, cy + r], outline=color, width=lw)
    # вертикальный меридиан (эллипс)
    draw.ellipse([cx - r * 0.45, cy - r, cx + r * 0.45, cy + r], outline=color, width=lw)
    # параллели
    draw.line([cx - r, cy, cx + r, cy], fill=color, width=lw)
    half = int(r * 0.55)
    chord = int((r * r - half * half) ** 0.5)
    draw.line([cx - chord, cy - half, cx + chord, cy - half], fill=color, width=lw)
    draw.line([cx - chord, cy + half, cx + chord, cy + half], fill=color, width=lw)


# Соответствие ключа ссылки функции отрисовки логотипа
LOGO_DRAWERS = {
    'vk': draw_vk,
    'inst': draw_inst,
    'max': draw_max,
    'site': draw_site,
}


def load_font(size):
    """Пробует взять жирный системный шрифт, иначе — встроенный PIL."""
    for name in ('arialbd.ttf', 'arial.ttf', 'DejaVuSans-Bold.ttf'):
        try:
            return ImageFont.truetype(name, size)
        except OSError:
            continue
    return ImageFont.load_default()


def add_logo(qr_img, key):
    """Рисует в центре QR белую подложку и логотип соцсети."""
    img = qr_img.copy()
    draw = ImageDraw.Draw(img)
    pad = int(SIZE * LOGO_RATIO)
    x = (SIZE - pad) // 2
    y = (SIZE - pad) // 2
    # белая подложка со скруглёнными углами
    draw.rounded_rectangle([x, y, x + pad, y + pad], radius=int(pad * 0.15), fill='white')
    # сам логотип чуть меньше подложки (поля 12%)
    m = int(pad * 0.12)
    LOGO_DRAWERS[key](draw, x + m, y + m, pad - 2 * m)
    return img


def main():
    os.makedirs(OUT_DIR, exist_ok=True)
    for key, url in LINKS.items():
        img = add_logo(make_base_qr(url), key)
        path = os.path.join(OUT_DIR, key + '.png')
        img.save(path)
        print('saved:', path)


if __name__ == '__main__':
    main()
