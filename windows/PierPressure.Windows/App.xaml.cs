using PierPressure.Windows.Views;

namespace PierPressure.Windows;

public partial class App : Application
{
    public App()
    {
        InitializeComponent();
        MainPage = new NavigationPage(new MenuPage());
    }
}
