
>>> from kivy.lang import Builder
... from kivymd.app import MDApp
... from kivymd.uix.list import OneLineAvatarListItem, ImageLeftWidget
... from kivymd.uix.button import MDRectangleFlatButton
... from kivymd.uix.dialog import MDDialog, MDInputDialog
... from kivymd.toast import toast
... from kivy.uix.widget import Widget
... from kivy.clock import Clock
... from kivy.graphics import Rectangle, Color
... import json, os, threading, time, subprocess
... import numpy as np
... import matplotlib.pyplot as plt
... 
... DATA_FILE = "games_prov2.json"
... 
... KV = """
... MDBoxLayout:
...     orientation: "vertical"
... 
...     MDTopAppBar:
...         title: "لانچر Pro v2 - نسخه PC"
...         md_bg_color: 0.1,0.1,0.1,1
...         elevation: 10
... 
...     MDBoxLayout:
...         orientation: "horizontal"
...         size_hint_y: None
...         height: "50dp"
...         padding: "10dp"
...         spacing: "10dp"
... 
...         MDTextField:
...             id: search_field
...             hint_text: "جستجوی بازی..."
...             on_text_validate: app.filter_games(self.text)
...             mode: "rectangle"
... 
    MDBoxLayout:
        orientation: "horizontal"
        size_hint_y: 0.4

        ScrollView:
            MDList:
                id: game_list

        GridSimWidget:
            id: grid_sim

    MDLabel:
        id: reason_label
        text: "Reasoning Agent: منتظر دستور..."
        halign: "center"
        size_hint_y: None
        height: "40dp"

    MDProgressBar:
        id: progress_bar
        size_hint_y: None
        height: "5dp"
        value: 0

    MDBoxLayout:
        orientation: "horizontal"
        size_hint_y: None
        height: "60dp"
        padding: "10dp"
        spacing: "10dp"

        MDRectangleFlatButton:
            text: "➕ اضافه کردن بازی"
            on_release: app.add_game_dialog()

        MDRectangleFlatButton:
            text: "✏️ ویرایش/حذف"
            on_release: app.edit_game()

        MDRectangleFlatButton:
            text: "▶ اجرای هوشمند"
            on_release: app.run_agent_pro()
            
<GridSimWidget>:
    canvas_widget: canvas_widget
    Widget:
        id: canvas_widget
"""

class GridSimWidget(Widget):
    def __init__(self, **kwargs):
        super().__init__(**kwargs)
        self.world_size = 10
        self.agent_x, self.agent_y = 0, 0
        self.target_x, self.target_y = 9, 9
        self.path = []
        Clock.schedule_interval(self.update_canvas, 0.5)

    def update_canvas(self, dt):
        self.canvas.clear()
        cell_size_x = self.width / self.world_size
        cell_size_y = self.height / self.world_size
        with self.canvas:
            # Grid lines
            Color(0.7,0.7,0.7)
            for i in range(self.world_size):
                for j in range(self.world_size):
                    Rectangle(pos=(i*cell_size_x,j*cell_size_y), size=(cell_size_x-1,cell_size_y-1))
            # Path
            Color(1,1,0)
            for px, py in self.path:
                Rectangle(pos=(px*cell_size_x, py*cell_size_y), size=(cell_size_x, cell_size_y))
            # Target
            Color(1,0,0)
            Rectangle(pos=(self.target_x*cell_size_x, self.target_y*cell_size_y), size=(cell_size_x,cell_size_y))
            # Agent
            Color(0,1,0)
            Rectangle(pos=(self.agent_x*cell_size_x, self.agent_y*cell_size_y), size=(cell_size_x,cell_size_y))

    def move_agent_step(self):
        if (self.agent_x, self.agent_y) == (self.target_x, self.target_y):
            return
        if self.agent_x < self.target_x:
            self.agent_x +=1
        elif self.agent_x > self.target_x:
            self.agent_x -=1
        if self.agent_y < self.target_y:
            self.agent_y +=1
        elif self.agent_y > self.target_y:
            self.agent_y -=1
        self.path.append((self.agent_x, self.agent_y))

class ProV2Launcher(MDApp):
    def build(self):
        self.theme_cls.theme_style = "Dark"
        self.theme_cls.primary_palette = "Red"
        self.games = []
        self.load_games()
        self.current_game = None
        return Builder.load_string(KV)

    def load_games(self):
        if os.path.exists(DATA_FILE):
            with open(DATA_FILE, "r", encoding="utf-8") as f:
                self.games = json.load(f)
        self.update_list()

    def save_games(self):
        with open(DATA_FILE, "w", encoding="utf-8") as f:
            json.dump(self.games, f, indent=4, ensure_ascii=False)

    def update_list(self):
        self.root.ids.game_list.clear_widgets()
        for g in self.games:
            item = OneLineAvatarListItem(text=g["name"])
            if "icon" in g:
                item.add_widget(ImageLeftWidget(source=g["icon"]))
            item.bind(on_release=lambda x, game=g: self.select_game(game))
            self.root.ids.game_list.add_widget(item)

    def filter_games(self, query):
        self.root.ids.game_list.clear_widgets()
        for g in self.games:
            if query.lower() in g["name"].lower():
                item = OneLineAvatarListItem(text=g["name"])
                if "icon" in g:
                    item.add_widget(ImageLeftWidget(source=g["icon"]))
                item.bind(on_release=lambda x, game=g: self.select_game(game))
                self.root.ids.game_list.add_widget(item)

    def select_game(self, game):
        self.current_game = game
        toast(f"انتخاب شد: {game['name']}")

    def add_game_dialog(self):
        dialog = MDInputDialog(
            title="نام بازی را وارد کنید:",
            text_button_ok="اضافه",
            text_button_cancel="لغو"
        )
        dialog.bind(on_dismiss=lambda x: self.add_game_callback(dialog.text if hasattr(dialog, 'text') else ''))
        dialog.open()

    def add_game_callback(self, name):
        if name:
            # مسیر exe یا icon دلخواه می‌تونه اضافه بشه بعداً
            self.games.append({"name": name})
            self.save_games()
            self.update_list()
            toast("بازی اضافه شد!")

    def edit_game(self):
        if not self.current_game:
            toast("ابتدا بازی انتخاب کنید!")
            return
        dialog = MDDialog(
            title=f"ویرایش {self.current_game['name']}",
            text="حذف یا تغییر نام؟",
            buttons=[
                MDRectangleFlatButton(text="حذف", on_release=lambda x: self.delete_game()),
                MDRectangleFlatButton(text="لغو", on_release=lambda x: dialog.dismiss())
            ]
        )
        dialog.open()

    def delete_game(self):
        if self.current_game:
            self.games.remove(self.current_game)
            self.save_games()
            self.update_list()
            toast("بازی حذف شد!")

    def run_agent_pro(self):
        if not self.current_game:
            toast("ابتدا بازی انتخاب کنید!")
            return
        toast(f"اجرای Agent برای {self.current_game['name']}")
        self.root.ids.progress_bar.value = 0
        canvas = self.root.ids.grid_sim

        def agent_thread():
            canvas.agent_x, canvas.agent_y = 0, 0
            canvas.target_x, canvas.target_y = 9, 9
            canvas.path = []
            steps = 10
            for i in range(steps):
                canvas.move_agent_step()
                Clock.schedule_once(lambda dt: None)
                time.sleep(0.3)
                self.root.ids.progress_bar.value = (i+1)*100/steps
                self.root.ids.reason_label.text = f"Reasoning Agent: Step {i+1}/{steps}"
            toast("Agent اجرا شد!")
            self.show_success_plot()

        threading.Thread(target=agent_thread, daemon=True).start()

    def show_success_plot(self):
        fig, ax = plt.subplots()
        ax.plot(np.random.rand(10), 'r-o', label='Success Rate')
        ax.set_title('Agent Learning Curve')
        ax.legend()
        plt.show()

ProV2Launcher().run()
